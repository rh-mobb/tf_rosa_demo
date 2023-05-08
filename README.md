# Using Terraform with ROSA Bring-your-own-VPC

The use of Terraform to manage the lifecycle of cloud resources is an extremely common pattern, and has led to a number of customer questions around "How can I manage ROSA with Terraform?"

This repo contains a working example of how to use Terraform to provision a ROSA cluster on a customer-provided VPC using [Red Hat Terraform provider](https://registry.terraform.io/providers/terraform-redhat/ocm/latest).

## Prerequisites

Using the code in the repo will require having the following tools installed:

- The Terraform CLI
- The AWS CLI
- The ROSA CLI

>The [ASDF tool](https://asdf-vm.com/) is an excellent way to manage versions of these tools if you're unfarmiliar with it

Additionally, Terraform repos often have a local variables file (`terraform.tfvars`) that is **not** committed to the repo because it will often have creds or API keys in it. For this repo, it's quite simple:

```hcl
cat << EOF > terraform.auto.tfvars
cluster_name = "rosa-test"
compute_nodes = "3"  # Set to 3 for HA, 2 for single-AZ
offline_access_token = "**************" # Get from https://console.redhat.com/openshift/token/rosa/show
rosa_version = "4.10.15" # Needs to be a supported version by ROSA
aws_region           = "us-east-2" # Optional, only if you're not selecting us-west-2 region
availability_zones   = ["us-east-2a", "us-east-2b", "us-east-2c"] # Optional, only if you're not selecting us-west-2 region

htpasswd_username = "kubeadmin"
htpasswd_password = "*********"
EOF
```

## Getting Started

1. Clone this repo down

   ```bash
   git clone https://github.com/rh-mobb/tf_rosa_demo.git
   cd tf_rosa_demo
   ```

1. Initialize Terraform

   ```bash
   terraform init
   ```

### Public ROSA Cluster in STS mode

> Note: this is the default behavior for the Terraform code and will result in a public ROSA cluster in STS mode.

1. Check for any variables in `vars.tf` that you want to change such as the cluster name.

1. Plan the Terraform configuration

   ```bash
   terraform plan -out rosa.plan
   ```

1. Apply the Terraform plan

   ```bash
   terraform apply rosa.plan
   ```

### Private-Link ROSA Cluster in STS mode

> This will create a Private-Link ROSA cluster in STS mode, it will use a public subnet for egress traffic (Nat GW / Internet Gateway) and a private subnet for the cluster itself and its ingress (API, default route, etc).

1. Check for any variables in `vars.tf` that you want to change such as the cluster name.

1. Plan the Terraform configuration

   > Note: You can set the `enable_private_link` variable in your `.tfvars` if you prefer.

   ```bash
   terraform plan -var "enable_private_link=true" -out rosa.plan
   ```

1. Apply the Terraform plan

   ```bash
   terraform apply rosa.plan
   ```

## Further reading

Creating a VPC via Terraform can be done by provisioning individual resources (this example creates 29 separate ones), but AWS provides a [very useful and well-supported Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) for creating VPCs that requires only a few values to be set and handles the heavy lifting. This module is called in the `vpc.tf` file.

For complex Private-Link scenarios including Transit Gateways we have a [terraform module](https://registry.terraform.io/modules/rh-mobb/rosa-privatelink-vpc/aws/latest) that can be used to assist in creating a VPC with Private-Link.

The VPC for this example follows the AWS "private" reference architecture:

- Spread across three availability zones
- Three private subnets to house compute resources
- Three public subnets to support exposing services via load balancer(s)
