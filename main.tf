terraform {
    required_providers {
        ocm = {
            version = ">= 0.1"
            source = "openshift-online/ocm"
        }
        okta = {
        source = "okta/okta"
        version = "3.29.0"
        }
        shell = {
            source = "scottwinkler/shell"
            version = "1.7.10"
        }
    }
}
 
provider "aws" {
    profile = "default"

    # This is necessary so TF doesn't try to remove the rosa-created labels
    # on various resources
    ignore_tags {
        key_prefixes = ["kubernetes.io/"]
    }
}

provider "ocm" {
    token = "${var.ocm_token}"
}

provider "okta" {
  org_name  = "dev-34242021"
  base_url  = "okta.com"
  api_token = "00F85O2r5ai8iPORhV2j6JdYjJmRquhycKiQhXN8l_"
}

provider "shell" {
    interpreter = ["/bin/sh", "-c"]
    enable_parallelism = false

    sensitive_environment = {
        # Need to probably have AWS creds
        # Also need to have OCM creds?
    }
}