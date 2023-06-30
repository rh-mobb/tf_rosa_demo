terraform {
  required_providers {
    rhcs = {
      version = ">= 1.0.5"
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

#data "aws_iam_user" "admin" {
#  user_name = "osdCcsAdmin"
#  count     = var.enable_sts ? 0 : 1
#}
