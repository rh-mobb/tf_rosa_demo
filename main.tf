terraform {
  required_providers {
    rhcs = {
      version = "~> 1.2"
      source  = "terraform-redhat/rhcs"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "rhcs" {
  token = var.offline_access_token
  url   = var.url
}

provider "aws" {
  region = var.aws_region
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
  profile = "default"

  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}

data "aws_caller_identity" "current" {}

data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.cluster_name
}
