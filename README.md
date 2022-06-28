# Using Terraform with ROSA Bring-your-own-VPC

The use of Terraform to manage the lifecycle of cloud resources is an extremely common pattern, and has led to a number of customer questions around "How can I manage ROSA with Terraform?"

Until the full-fledged TF provider for ROSA (which is on the product roadmap) is released, this repo contains a working example of how to use Terraform to provision a ROSA cluster on a customer-provided VPC using a generic TF provider and some shell scripts.

## Setup

Using the code in the repo will require having the following tools installed:

- The Terraform CLI
- The AWS CLI
- The ROSA CLI

>The [ASDF tool](https://asdf-vm.com/) is an excellent way to manage versions of these tools if you're unfarmiliar with it

Additionally, Terraform repos often have a local variables file (`terraform.tfvars`) that is **not** committed to the repo because it will often have creds or API keys in it. For this repo, it's quite simple:

```hcl
rosa_cluster_name = "rosa-test"
rosa_compute_node_count = "3"  # Set to 3 for HA, 2 for single-AZ
rosa_offline_access_token = "**************" # Get from console.redhat.com
rosa_version = "4.10.15" # Needs to be a supported version by ROSA
```
**TODO**

- [ ] Add a scripted `rosa login` to each stage
- [ ] Figure out best way to pass AWS creds (environment?)

For now, this works only when there is a configured set of AWS creds to use and a `rosa login` has already been done, so it's not yet ready for use in an automated environment.

## The VPC

Creating a VPC via Terraform can be done by provisioning individual resources (this example creates 29 separate ones), but AWS provides a [very useful and well-supported Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) for creating VPCs that requires only a few values to be set and handles the heavy lifting. This module is called in the `vpc.tf` file.

The VPC for this example follows the AWS "private" reference architecture:

- Spread across three availability zones
- Three private subnets to house compute resources
- Three public subnets to support exposing services via load balancer(s)

This is what's required for an HA ROSA cluster in "private" configuration. A "public" cluster would only need three public subnets, but there's really no advantage to using that deployment model aside from not having to pay AWS for NAT resources.

A ROSA "privatelink" deployment can use the same configuration but requires slightly different parameters to the ROSA script as will be explored below.

## The ROSA scripts

Terraform manages state for the resources it creates rather than simply executing a series of commands. In order to use the `rosa` CLI command, a wrapper is needed that not only executes the command with the needed input parameters, but generates a state (which is a chunk of JSON) that represents all the information about the cluster that Terraform needs.

The first piece of the puzzle is the `shell_script` [Terraform provider](https://registry.terraform.io/providers/scottwinkler/shell/latest). It's added to the configuration in the `main.tf` file under the `required_providers` block. A `terraform init` will be necessary to get the provider installed.

The provider allows for scripts to be designated for the four lifecycle actions that Terraform defines:

1. Create
1. Update
1. Read
1. Destroy

At a minimum, a Create and Update action are needed. The Read action is pretty easy to define in this case as well. 

The `shell_script` provider renders *all* of the scripts provided at the time of creation of a resource and saves the rendered scripts in state so when the time comes to delete the resource (or if someone deletes is manually), the code is still available to perform the action.

The current layout has specific scripts for specific uses cases (e.g., private with STS, privatelink with STS, etc.) The directory names under `scripts` are reflective of those. 

### `create.sh`


The reason for separate directories is to handle the need for different flags to the `rosa` command, which is the first block of the script. 

```bash
rosa create cluster \
--color never \
--cluster-name=$ROSA_CLUSTER_NAME \
--sts \
--role-arn arn:aws:iam::660250927410:role/ManagedOpenShift-Installer-Role \
--support-role-arn arn:aws:iam::660250927410:role/ManagedOpenShift-Support-Role \
--controlplane-iam-role arn:aws:iam::660250927410:role/ManagedOpenShift-ControlPlane-Role \
--worker-iam-role arn:aws:iam::660250927410:role/ManagedOpenShift-Worker-Role \
--external-id $ROSA_CLUSTER_NAME \
--multi-az \
--region $ROSA_REGION \
--version $ROSA_VERSION \
--compute-nodes $ROSA_COMPUTE_NODE_COUNT \
--compute-machine-type $ROSA_COMPUTE_NODE_INSTANCE_TYPE \
--machine-cidr $ROSA_MACHINE_CIDR \
--service-cidr 172.30.0.0/16 \
--pod-cidr 10.128.0.0/14 \
--host-prefix $ROSA_HOST_PREFIX \
--subnet-ids $ROSA_SUBNET_IDS \
--yes
```

Creating a "private" actually requires passing both public and private subnet types to the the `rosa` command (as in, it will throw an error if they're not both present). Because the `--multi-az` flag is also present, it requires three of each.

Creating a "privatelink" cluster will actually require that **only** private subnets are passed (again, three required in this case because `--multi-az` is set). This also sets `--private-link` to the command as well.

```bash
if [ $? -eq 0 ]; then
    ...
```
If the initial cluster command returns a `0`, subsequent steps proceed:

- Creation of the operator roles
- Creation of the OIDC provider

```bash
    echo "Creating operator roles..."
    rosa create operator-roles --mode auto --yes --cluster $ROSA_CLUSTER_NAME
    echo "Creating OIDC provider..."
    rosa create oidc-provider --mode auto --yes --cluster $ROSA_CLUSTER_NAME
```

The cluster status will be stuck in 'awaiting XXXXX` until both of those are done, hence their integration here. This is **not** proper Terraform however, as those resources would ideally have their own state and creation blocks.

The script then tails the install logs with the `--watch` flag so it will stop when deployment is complete.

```bash
    echo "Monitoring logs until cluster provisioning is complete..."
    rosa logs install --cluster $ROSA_CLUSTER_NAME --watch
```

Finally, the `describe` command is run, and with the `--output json` flag, because whatever the script returns back to the controlling `terraform` process is saved as the state for that resource, so as long as it's valid JSON, it's usable.

```bash
    echo "Getting final state for storage as TF state..."
    # For debugging, a '| tee state.json' can be added below
    rosa describe cluster --cluster $ROSA_CLUSTER_NAME --output json
```

### `read.sh`


For ROSA, this is very simple in that it's a single command. Like create, it needs the addition of a `rosa login` and injection of AWS creds so it can be run in an automated environment.

### `delete.sh`


```bash
IN=$(cat)
CLUSTER_ID=$(echo $IN | jq -r .id)

rosa delete cluster --cluster $ROSA_CLUSTER_NAME --yes
if [ $? -eq 0 ]; then
    rosa logs uninstall --cluster $ROSA_CLUSTER_NAME --watch
    rosa delete operator-roles --cluster $CLUSTER_ID --yes --mode auto
    rosa delete oidc-provider --cluster $CLUSTER_ID --yes --mode auto
fi
```

The delete action uses some similar functionality as create in terms of the `--watch` flag on logs to determine when the cluster is truly deleted, and then cleaning up the operator and OIDC resources.

The first two lines demonstrate another fundamental of Terraform: whatever state is attached to a resource is passed to the provider, which in this case is used to determine the cluster ID. Because the OIDC and operator roles persist after the cluster is gone (and the ability to refer to it by name as well), the ID is needed. In this case, a simple `echo` and query with `jq` gets it.