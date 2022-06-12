terraform {
    required_providers {
        ocm = {
            version = ">= 0.1"
            source = "openshift-online/ocm"
        }
        shell = {
            source = "scottwinkler/shell"
            version = "1.7.10"
        }
    }
}
 
provider "ocm" {
    token = "${var.ocm_token}"
}

provider "aws" {
    # region = "${var.region}"
    # access_key = "${var.access_key}"
    # secret_key = "${var.secret_key}"
    profile = "default"

    ignore_tags {
        key_prefixes = ["kubernetes.io/"]
    }
}

provider "shell" {
    interpreter = ["/bin/sh", "-c"]
    enable_parallelism = false

    sensitive_environment = {
        # Need to probably have AWS creds
        # Also need to have OCM creds?
    }
}
