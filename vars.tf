variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ROSA cluster to create"
  default     = "poc-frontier"
}


# variable "rosa_version" {
#   type        = string
#   description = "The version of ROSA to be deployed"
#   default     = "4.12.5"
# }

variable "compute_nodes" {
  type        = string
  description = "The number of computer nodes to create. Must be a minimum of 2 for a single-AZ cluster, 3 for multi-AZ."
  default     = "3"
}

variable "compute_node_instance_type" {
  type        = string
  description = "The EC2 instance type to use for compute nodes"
  default     = "m5.xlarge"
}

variable "host_prefix" {
  type        = string
  description = "The subnet mask to assign to each compute node in the cluster"
  default     = "23"
}

variable "offline_access_token" {
  type        = string
  description = "The OCM API access token for your account"
}

variable "availability_zones" {
  type        = list(any)
  description = "The availability zones to use for the cluster"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "machine_cidr_block" {
  type        = string
  description = "value of the CIDR block to use for the VPC"
  default     = "10.66.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(any)
  description = "The CIDR blocks to use for the private subnets"
  default     = ["10.66.1.0/24", "10.66.2.0/24", "10.66.3.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(any)
  description = "The CIDR blocks to use for the public subnets"
  default     = ["10.66.101.0/24", "10.66.102.0/24", "10.66.103.0/24"]
}

variable "enable_private_link" {
  type        = bool
  description = "This enables private link"
  default     = false
}

variable "enable_sts" {
  type        = bool
  description = "This enables STS"
  default     = true
}

# variable "aws_access_key_id" {
#   type = string
#   description = "The AWS access key ID to use for the cluster"
# }

# variable "aws_secret_access_key" {
#   type = string
#   description = "The AWS secret access key to use for the cluster"
# }

