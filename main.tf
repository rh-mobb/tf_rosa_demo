terraform {
  required_providers {
    ocm = {
      source = "terraform-redhat/ocm"
      version = "1.0.1"
    }
  }
}

provider "ocm" {
  token = var.offline_access_token
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


data "aws_iam_user" "admin" {
  user_name = "osdCcsAdmin"
  count     = var.enable_sts ? 0 : 1
}
