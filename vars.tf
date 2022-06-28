variable "aws_account_id" {
    type = string
    description = "The AWS account in which the cluster will be built"
}

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

variable "external_id" {
    type = string
    description = "Optional external ID to link to ROSA cluster"
    default = ""
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

variable "offline_access_token" {
    type = string
    description = "The OCM API access token for your account"
}

/* variable "idp_name" {}

variable "idp_type" {
    type = string
    description = "The type of IDP to be provisioned"
    validation {
        condition = contains(["github", "gitlab", "google", "htpasswd", "ldap", "openid"], var.idp_type)
        error_message = "IDP type must be one of [github gitlab google htpasswd ldap openid]"
    }
} */