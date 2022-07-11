variable "aws_region" {
    type = string
}

variable "cluster_name" {
    type = string
    description = "The name of the ROSA cluster to create"
}

variable "network_type" {
        type = string
        validation {
            condition = contains(["public", "private", "privatelink"], var.network_type)
            error_message = "Network type must be one of [public,private,privatelink]"
        }
}

variable "ocp_version" {
    type = string
    description = "The version of ROSA to be deployed"
}

variable "compute_node_count" {
    type = string
    description = "The number of computer nodes to create. Must be a minimum of 2 for a single-AZ cluster, 3 for multi-AZ."
}

variable "compute_node_instance_type" {
    type = string
    description = "The EC2 instance type to use for compute nodes"
    default = "m5.xlarge"
}

variable "host_prefix" {
    type = string
    description = "The subnet mask to assign to each compute node in the cluster"
    default = "23"
}

variable "ocm_token" {
    type = string
    description = "The OCM API access token for your account"
}

variable "operator_role_prefix" {
  type = string  
  description = "A prefix value for operator role IDs"
}

variable "ssh_key_name" {
    type = string
    description = "The SSH key name (in AWS) to associate with the bastion"
}
