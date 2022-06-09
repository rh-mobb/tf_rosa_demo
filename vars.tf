variable "rosa_cluster_name" {
    type = string
    description = "The name of the ROSA cluster to create"
}

variable "rosa_version" {
    type = string
    description = "The version of ROSA to be deployed"
}

variable "rosa_compute_node_count" {
    type = string
    description = "The number of computer nodes to create. Must be a minimum of 2 for a single-AZ cluster, 3 for multi-AZ."
}

variable "rosa_compute_node_instance_type" {
    type = string
    description = "The EC2 instance type to use for compute nodes"
    default = "m5.xlarge"
}

variable "rosa_host_prefix" {
    type = string
    description = "The subnet mask to assign to each compute node in the cluster"
    default = "23"
}

variable "rosa_offline_access_token" {
    type = string
    description = "The OCM API access token for your account"
}