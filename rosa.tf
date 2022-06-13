resource "shell_script" "rosa_cluster" {
    lifecycle_commands {
        create  = templatefile(
            "${path.module}/templates/cluster/create.tftpl", 
            { 
                debug = true,
                sts = true,
                cluster_name = var.cluster_name,
                external_id = var.external_id,
                ocp_version = var.ocp_version,
                network_type = var.network_type,
                privatelink = true,
                subnet_ids = module.vpc.private_subnets,
                host_prefix = var.host_prefix,
                compute_node_count = var.compute_node_count,
                compute_node_instance_type = var.compute_node_instance_type,
                aws_account_id = var.aws_account_id,
                aws_region = var.aws_region,
                machine_cidr_block = module.vpc.vpc_cidr_block
            })
        delete  = templatefile(
            "${path.module}/templates/cluster/delete.tftpl", 
            { 
                debug = true,
                cluster_name = var.cluster_name
            })
        read    = templatefile(
            "${path.module}/templates/cluster/read.tftpl", 
            { 
                debug = true, 
                cluster_name = var.cluster_name
            })
    }

    # Note that the rosa CLI command will fail if you pass any
    # non-private subnets to it along with the `--private` flag

    environment = {}

    sensitive_environment = {
        ROSA_OFFLINE_ACCESS_TOKEN = var.offline_access_token        
    }

    # This is necessary to ensure *all* VPC module resources are built
    # before the cluster build is launched
    depends_on = [
        module.vpc
    ]
}