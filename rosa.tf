resource "shell_script" "rosa_sts_public" {
    lifecycle_commands {
        create  = file("${path.module}/scripts/rosa/sts_public/create.sh")
        delete  = file("${path.module}/scripts/rosa/sts_public/delete.sh")
        read    = file("${path.module}/scripts/rosa/sts_public/read.sh")
    }

    # Note that the rosa CLI command will fail if you pass any
    # non-private subnets to it along with the `--private` flag

    environment = {
        ROSA_CLUSTER_NAME = var.rosa_cluster_name
        ROSA_VERSION = var.rosa_version
        ROSA_REGION = "us-west-2"
        ROSA_COMPUTE_NODE_COUNT = var.rosa_compute_node_count
        ROSA_COMPUTE_NODE_INSTANCE_TYPE = var.rosa_compute_node_instance_type
        ROSA_HOST_PREFIX = var.rosa_host_prefix
        ROSA_MACHINE_CIDR = module.vpc.vpc_cidr_block
        ROSA_SUBNET_IDS = join(",", concat(module.vpc.private_subnets, module.vpc.public_subnets))
    }

    sensitive_environment = {
        ROSA_OFFLINE_ACCESS_TOKEN = var.rosa_offline_access_token        
    }

    # This is necessary to ensure *all* VPC module resources are built
    # before the cluster build is launched
    depends_on = [
        module.vpc
    ]
}