locals {
    base_domain = regex("https://console-openshift-console.apps.(?P<name>[a-z1-9-.]+)", jsondecode(shell_script.rosa_cluster.output["console"]).url)
}

resource "okta_app_oauth" "rosa" {
  label                      = "${var.cluster_name}-${var.aws_region}-auth"
  type                       = "web"
  grant_types                = ["authorization_code"]
  redirect_uris              = ["https://oauth-openshift.apps.${local.base_domain.name}/oauth2callback/okta"]
  response_types             = ["code"]
  implicit_assignment        = true
}