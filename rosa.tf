data "aws_caller_identity" "current" {}

locals {
  sts_roles = {
      role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
      support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Support-Role",
      instance_iam_roles = {
        master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-ControlPlane-Role",
        worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Worker-Role"
      },
      operator_role_prefix = var.cluster_name,
}
  tags = {
      "owner" = data.aws_caller_identity.current.arn
     }
}


resource "ocm_cluster_rosa_classic" "rosa" {
  name                 = var.cluster_name
  
  cloud_region         = var.aws_region
  aws_account_id       = data.aws_caller_identity.current.account_id 
  tags                 = local.tags

  replicas             = var.replicas
  availability_zones   = var.availability_zones
  aws_private_link     = var.enable_private_link 
  aws_subnet_ids       = var.enable_private_link ? module.rosa-vpc.private_subnets : concat(module.rosa-vpc.private_subnets, module.rosa-vpc.public_subnets) 
  compute_machine_type = var.compute_node_instance_type
  multi_az             = length(module.rosa-vpc.private_subnets) == 3 ? true : false
  version              = "openshift-v${var.rosa_version}" 
  machine_cidr         = module.rosa-vpc.vpc_cidr_block
  properties           = { rosa_creator_arn = data.aws_caller_identity.current.arn } 
  sts                  = var.enable_sts ? local.sts_roles : null
  depends_on           = [ module.rosa-vpc ]
}


data "ocm_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.cluster_name
}


module "operator_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.4"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = ocm_cluster_rosa_classic.rosa.id
  rh_oidc_provider_thumbprint = ocm_cluster_rosa_classic.rosa.sts.thumbprint
  rh_oidc_provider_url        = ocm_cluster_rosa_classic.rosa.sts.oidc_endpoint_url
  operator_roles_properties   = data.ocm_rosa_operator_roles.operator_roles.operator_iam_roles
}

resource "ocm_cluster_wait" "rosa" {
  cluster = ocm_cluster_rosa_classic.rosa.id
  timeout = 60
}

