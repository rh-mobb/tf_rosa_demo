# Using Terraform with ROSA Bring-your-own-VPC

The use of Terraform to manage the lifecycle of cloud resources is an extremely common pattern, and has led to a number of customer questions around "Can I manage ROSA with Terraform?"

This repo shows how to provision a cluster on top of a VPC defined by Terraform, and also automates some Day 1 tasks like adding an OIDC IDP and installing operators.

## Setup

Using the code in the repo will require having the following tools installed:

- The Terraform CLI
- The `oc` OpenShift CLI tool

While not technically "required", it's also a good idea to have the `rosa` and `aws` CLI tools available as well.

>The [ASDF tool](https://asdf-vm.com/) is an excellent way to manage versions of these tools if you're unfarmiliar with it

Additionally, Terraform repos often have a local variables file (`terraform.tfvars`) that is **not** committed to the repo because it will often have creds or API keys in it. For this repo, it's quite simple:

```hcl
# The region to build the environment in
aws_region = "us-west-2"

cluster_name = "test-cluster"
 
# Minimum for multi-AZ
compute_node_count = "3"

# From console.redhat.com, at the bottom of the 'Downloads' page
ocm_token = "$REDHAT_OCM_OFFLINE_TOKEN"

# Look at the 'Releases' page in the console, or run `rosa list versions`
# The latest version will always be at the top of the list
ocp_version = "4.10.20"

# Needs to be one of ["public"|"private"|"privatelink"]
network_type = "privatelink"

# Add a bit of randomness the operator role names so they're unique
# Can be generated with a:
# head -c24 < /dev/random | base64 | LC_CTYPE=C tr -dc 'a-z0-9' | cut -c -4
operator_role_prefix = "x76e"
```

## The VPC

Creating a VPC via Terraform can be done by provisioning individual resources (this example creates 29 separate ones), but AWS provides a [very useful and well-supported Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) for creating VPCs that requires only a few values to be set and handles the heavy lifting. This module is called in the `vpc.tf` file.

The VPC for this example follows the AWS "private" reference architecture:

- Spread across three availability zones
- Three private subnets to house compute resources
- Three public subnets to support exposing services via load balancer(s)

### Private vs. Privatelink

The VPC example here is a "private" configuration per AWS terminology and best practices. ROSA clusters also have a network type parameter that can be:

- `public`
- `private`
- `privatelink`

This parameter doesn't have any impact on how the underlying VPC is configured, it refers to how the cluster is accessed:

- Public clusters have a public load balancer that exposes the Kubernetes API.
- Private clusters have an internal load balancer (private IP) for the K8S API.
- Privatelink clusters are the same as Private with the additional security granted by having all SRE management traffic enter the VPC via a private endpoint inside the VPC.

Privatelink is a capability that was added to ROSA more recently, but for a variety of reasons should be considered the default, and thus this repo shows the creation of a Privatelink cluster.

# The Cluster

Everything created by the OCM provider lives in the `ocp_cluster.tf` file.

There are a few idiosyncracies related to use of the OCM TF provider that should be kept in mind:

1. The creation of the cluster resource should have an explicit `depends_on` for the VPC itself.
1. The cluster resource shouldn't wait for creation, because the OCM API can't actually proceed with cluster creation until the IAM roles are created as well, but doing so requires the cluster ID. In practice, what this means is that the cluster shows 'created', but any IDPs stay in 'creating' in the TF output until the cluster itself is up and running.
1. For that reason, any downstream provisioning via the `k8s` or `helm` providers should depend on the completion of the IDP.
1. Also note that the AWS provider needs to be told to ignore any tags that start with `kubernetes.io/` so it won't remove them on subsequent Terraform runs. If it is allowed to remove these tags, cluster management 
