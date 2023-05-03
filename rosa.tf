locals {
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
    support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Support-Role",
    operator_iam_roles = [
      {
        name      = "cloud-credential-operator-iam-ro-creds",
        namespace = "openshift-cloud-credential-operator",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cloud-credential-operator-cloud-c",
      },
      {
        name      = "installer-cloud-credentials",
        namespace = "openshift-image-registry",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-image-registry-installer-cloud-cr",
      },
      {
        name      = "cloud-credentials",
        namespace = "openshift-ingress-operator",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-ingress-operator-cloud-credential",
      },
      {
        name      = "ebs-cloud-credentials",
        namespace = "openshift-cluster-csi-drivers",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cluster-csi-drivers-ebs-cloud-cre",
      },
      {
        name      = "cloud-credentials",
        namespace = "openshift-cloud-network-config-controller",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cloud-network-config-controller-c",
      },
      {
        name      = "aws-cloud-credentials",
        namespace = "openshift-machine-api",
        role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-machine-api-aws-cloud-credentials",
      },
    ]
    instance_iam_roles = {
      master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-ControlPlane-Role",
      worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Worker-Role"
    },
  }
  aws_access_key_id     = length(aws_iam_access_key.admin_key) > 0 ? aws_iam_access_key.admin_key[0].id : null
  aws_secret_access_key = length(aws_iam_access_key.admin_key) > 0 ? aws_iam_access_key.admin_key[0].secret : null
}

resource "aws_iam_access_key" "admin_key" {
  count = var.enable_sts ? 0 : 1
  user  = data.aws_iam_user.admin[0].user_name
}

resource "ocm_cluster" "rosa_cluster" {
  product        = "rosa"
  cloud_provider = "aws"
  name           = var.cluster_name
  #version        = var.rosa_version
  cloud_region   = var.aws_region
  compute_nodes  = var.compute_nodes
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_subnet_ids = var.enable_private_link ? module.rosa-vpc.private_subnets : concat(module.rosa-vpc.private_subnets, module.rosa-vpc.public_subnets)
  # aws_subnet_ids     = concat(module.rosa-vpc.private_subnets, module.rosa-vpc.public_subnets)
  machine_cidr     = module.rosa-vpc.vpc_cidr_block
  aws_private_link = var.enable_private_link
  # aws_private_link   = false
  multi_az           = length(module.rosa-vpc.private_subnets) == 3 ? true : false
  availability_zones = var.availability_zones
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  wait = var.enable_sts ? false : true
  sts  = var.enable_sts ? local.sts_roles : null
  depends_on = [
    module.rosa-vpc
  ]
  # aws_access_key_id     = local.aws_access_key_id
  # aws_secret_access_key = local.aws_secret_access_key
  aws_access_key_id     = var.enable_sts ? (length(aws_iam_access_key.admin_key) > 0 ? aws_iam_access_key.admin_key[0].id : null) : null
  aws_secret_access_key = var.enable_sts ? (length(aws_iam_access_key.admin_key) > 0 ? aws_iam_access_key.admin_key[0].secret : null) : null
  lifecycle {
    # prevent_destroy = true
  }
}

module "sts_roles" {
  count                = var.enable_sts ? 1 : 0
  source               = "rh-mobb/rosa-sts-roles/aws"
  create_account_roles = false
  clusters = [{
    id                   = ocm_cluster.rosa_cluster.id
    operator_role_prefix = var.cluster_name
  }]
}

resource "ocm_cluster_wait" "rosa_cluster_wait" {
  cluster = ocm_cluster.rosa_cluster.id
}
