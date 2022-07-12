locals {
  sts_roles = {
      role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
      support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Support-Role",
      operator_iam_roles = [
        {
          name =  "cloud-credential-operator-iam-ro-creds",
          namespace = "openshift-cloud-credential-operator",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cloud-credential-operator-cloud-c",
        },
        {
          name =  "installer-cloud-credentials",
          namespace = "openshift-image-registry",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-image-registry-installer-cloud-cr",
        },
        {
          name =  "cloud-credentials",
          namespace = "openshift-ingress-operator",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-ingress-operator-cloud-credential",
        },
        {
          name =  "ebs-cloud-credentials",
          namespace = "openshift-cluster-csi-drivers",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cluster-csi-drivers-ebs-cloud-cre",
        },
        {
          name =  "cloud-credentials",
          namespace = "openshift-cloud-network-config-controller",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-cloud-network-config-controller-c",
        },
        {
          name =  "aws-cloud-credentials",
          namespace = "openshift-machine-api",
          role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-openshift-machine-api-aws-cloud-credentials",
        },
      ]
      instance_iam_roles = {
        master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-ControlPlane-Role",
        worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Worker-Role"
      },
  }
}

resource "aws_iam_access_key" "admin_key" {
  user = data.aws_iam_user.admin.user_name
}

resource "ocm_cluster" "rosa_cluster" {
  name               = var.cluster_name
  cloud_provider     = "aws"
  cloud_region       = var.aws_region
  compute_nodes      = var.compute_nodes
  product            = "rosa"
  aws_account_id     = data.aws_caller_identity.current.account_id
  aws_subnet_ids     = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  machine_cidr       = module.vpc.vpc_cidr_block
  aws_private_link   = false
  multi_az           = true
  availability_zones = var.availability_zones
  properties         = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  wait = true
  # sts = local.sts_roles
    depends_on = [
        module.vpc
    ]
  aws_access_key_id     = aws_iam_access_key.admin_key.id
  aws_secret_access_key = aws_iam_access_key.admin_key.secret
  # lifecycle {
  #   prevent_destroy = true
  # }
  # version = "openshift-${var.rosa_version}"
}

# resource "shell_script" "rosa_cluster" {
#     lifecycle_commands {
#         create  = templatefile(
#             "${path.module}/templates/cluster/create.tftpl",
#             {
#                 debug = true,
#                 sts = true,
#                 cluster_name = var.cluster_name,
#                 external_id = var.external_id,
#                 ocp_version = var.ocp_version,
#                 network_type = var.network_type,
#                 privatelink = true,
#                 subnet_ids = module.vpc.private_subnets,
#                 host_prefix = var.host_prefix,
#                 compute_node_count = var.compute_node_count,
#                 compute_node_instance_type = var.compute_node_instance_type,
#                 aws_account_id = var.aws_account_id,
#                 aws_region = var.aws_region,
#                 machine_cidr_block = module.vpc.vpc_cidr_block
#             })
#         delete  = templatefile(
#             "${path.module}/templates/cluster/delete.tftpl",
#             {
#                 debug = true,
#                 cluster_name = var.cluster_name
#             })
#         read    = templatefile(
#             "${path.module}/templates/cluster/read.tftpl",
#             {
#                 debug = true,
#                 cluster_name = var.cluster_name
#             })
#     }

#     # Note that the rosa CLI command will fail if you pass any
#     # non-private subnets to it along with the `--private` flag

#     environment = {}

#     sensitive_environment = {
#         ROSA_OFFLINE_ACCESS_TOKEN = var.offline_access_token
#     }

#     # This is necessary to ensure *all* VPC module resources are built
#     # before the cluster build is launched
#     depends_on = [
#         module.vpc
#     ]
# }
