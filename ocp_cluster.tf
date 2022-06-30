locals {
  sts_roles = {
      role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
      support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Support-Role",
      operator_iam_roles = [
        {
          name =  "cloud-credential-operator-iam-ro-creds",
          namespace = "openshift-cloud-credential-operator",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-cloud-credential-operator-cloud-c",
        },
        {
          name =  "installer-cloud-credentials",
          namespace = "openshift-image-registry",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-image-registry-installer-cloud-cr",
        },
        {
          name =  "cloud-credentials",
          namespace = "openshift-ingress-operator",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-ingress-operator-cloud-credential",
        },
        {
          name =  "ebs-cloud-credentials",
          namespace = "openshift-cluster-csi-drivers",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-cluster-csi-drivers-ebs-cloud-cre",
        },
        {
          name =  "cloud-credentials",
          namespace = "openshift-cloud-network-config-controller",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-cloud-network-config-controller-c",
        },
        {
          name =  "aws-cloud-credentials",
          namespace = "openshift-machine-api",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.operator_role_prefix}-openshift-machine-api-aws-cloud-credentials",
        },
      ]
      instance_iam_roles = {
        master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-ControlPlane-Role",
        worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Worker-Role"
      },    
  }
}

resource "ocm_cluster" "rosa_cluster" {
  name           = var.cluster_name
  cloud_provider = "aws"
  cloud_region   = var.aws_region
  product        = "rosa"
  aws_account_id     = data.aws_caller_identity.current.account_id
  aws_subnet_ids = module.vpc.private_subnets
  machine_cidr = module.vpc.vpc_cidr_block
  multi_az = true
  aws_private_link = true
  availability_zones = module.vpc.azs
  /* proxy = {
    http_proxy = var.proxy
    https_proxy = var.proxy
  } */
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  wait = false
  sts = local.sts_roles
}

module sts_roles {
    source  = "rh-mobb/rosa-sts-roles/aws"
    create_account_roles = false
    clusters = [{
        id = ocm_cluster.rosa_cluster.id
        operator_role_prefix = var.operator_role_prefix
    }]
}

resource "ocm_identity_provider" "htpasswd" {
  cluster = ocm_cluster.rosa_cluster.id
  name    = "htpasswd"
  htpasswd = {
    username = "admin"
    password = "L0ngP@ssw0rd!"
  }
}

resource "ocm_group_membership" "my_admin" {
  cluster = ocm_cluster.rosa_cluster.id
  group   = "dedicated-admins"
  user    = "admin"
}