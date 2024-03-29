locals {
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
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

resource "rhcs_cluster_rosa_classic" "rosa" {
  name = var.cluster_name

  cloud_region   = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  tags           = local.tags

  replicas             = var.replicas
  availability_zones   = var.availability_zones
  aws_private_link     = var.enable_private_link
  aws_subnet_ids       = var.enable_private_link ? module.rosa-vpc.private_subnets : concat(module.rosa-vpc.private_subnets, module.rosa-vpc.public_subnets)
  compute_machine_type = var.compute_node_instance_type
  multi_az             = length(module.rosa-vpc.private_subnets) == 3 ? true : false
  version              = var.rosa_version
  machine_cidr         = module.rosa-vpc.vpc_cidr_block
  properties           = { rosa_creator_arn = data.aws_caller_identity.current.arn }
  sts                  = local.sts_roles
  depends_on           = [module.rosa-vpc]
}

module "operator_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.4"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = rhcs_cluster_rosa_classic.rosa.id
  rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa.sts.thumbprint
  rh_oidc_provider_url        = rhcs_cluster_rosa_classic.rosa.sts.oidc_endpoint_url
  operator_roles_properties   = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles
}

resource "rhcs_cluster_wait" "rosa" {
  cluster = rhcs_cluster_rosa_classic.rosa.id
  timeout = 60
}

resource "rhcs_identity_provider" "rosa_iam_htpasswd" {
  cluster = rhcs_cluster_rosa_classic.rosa.id
  name    = "httpasswd"
  htpasswd = {
    users = [{
      username = var.htpasswd_username
      password = var.htpasswd_password
    }]
  }
  depends_on = [
    rhcs_cluster_wait.rosa
  ]
}

resource "rhcs_group_membership" "htpasswd_admin" {
  cluster = rhcs_cluster_rosa_classic.rosa.id
  group   = "cluster-admins"
  user    = var.htpasswd_username
  depends_on = [
    rhcs_cluster_wait.rosa
  ]
}

output "rosa_api" {
  value = rhcs_cluster_rosa_classic.rosa.api_url
}

output "rosa_console" {
  value = rhcs_cluster_rosa_classic.rosa.console_url
}

output "rosa_htpasswd_username" {
  value = rhcs_identity_provider.rosa_iam_htpasswd.htpasswd.users[0].username
}

output "rosa_htpasswd_password" {
  value = rhcs_identity_provider.rosa_iam_htpasswd.htpasswd.users[0].password
  sensitive = true
}
