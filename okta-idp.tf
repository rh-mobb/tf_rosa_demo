# Get the cluster base domain, this will not be available until *after* the cluster is 
# up and running, see the `depends` block on line 69 below
locals {
  cluster_base_domain = regex("https://console-openshift-console.apps.(?P<name>.+)",ocm_cluster.rosa_cluster.console_url)
}

resource "okta_group" "ocp_admin" {
  name        = "ocp-admins"
  description = "Users who can access openshift cluster as admins"
}

resource "okta_group" "ocp_restricted_users" {
  name        = "ocp-restricted-users"
  description = "Users who can only view pods and services in default namespace"
}

# Assign users to the groups
data "okta_user" "admin" {
  search {
    name  = "profile.email"
    value = "thatcher.hubbard@gmail.com"
  }
}

resource "okta_group_memberships" "admin_user" {
  group_id = okta_group.ocp_admin.id
  users = [
    data.okta_user.admin.id
  ]
}

data "okta_user" "restricted_user" {
  search {
    name  = "profile.email"
    value = "biff.pokoroba@baconfortress.dev"
  }
}

resource "okta_group_memberships" "restricted_user" {
  group_id = okta_group.ocp_restricted_users.id
  users = [
    data.okta_user.restricted_user.id
  ]
}

# Create an OIDC application

resource "okta_app_oauth" "ocp_oidc" {
  label                      = "${var.cluster_name}-${var.aws_region}-auth"
  type                       = "web" # this is important
#  token_endpoint_auth_method = "none"   # this sets the client authentication to PKCE
  consent_method = "REQUIRED"
  grant_types = [
    "authorization_code"
  ]
  response_types = ["code"]
  redirect_uris = [
    "https://oauth-openshift.apps.${local.cluster_base_domain.name}/oauth2callback/openid",
  ]
  post_logout_redirect_uris = [
    "http://localhost:8000",
  ]
  lifecycle {
    ignore_changes = [groups]
  }

  # This is here to ensure the cluster is provisioned (and has an assigned API URL)
  # before the Okta OIDC resource tries to configure (it will fail if the $local.base_domain var is empty)
  depends_on = [
    ocm_identity_provider.htpasswd
  ]
}

# Assign groups to the OIDC application
resource "okta_app_group_assignments" "ocp_oidc_group" {
  app_id = okta_app_oauth.ocp_oidc.id
  group {
    id = okta_group.ocp_admin.id
  }
  group {
    id = okta_group.ocp_restricted_users.id
  }
}

output "ocp_oidc_client_id" {
  value = okta_app_oauth.ocp_oidc.client_id
}

output "ocp_oidc_client_secret" {
  value = okta_app_oauth.ocp_oidc.client_secret
  sensitive = true
}

# Create an authorization server

resource "okta_auth_server" "oidc_auth_server" {
  name      = "ocp-auth"
  audiences = ["http:://localhost:8000"]
}

output "ocp_oidc_issuer_url" {
  value = okta_auth_server.oidc_auth_server.issuer
}

# Add claims to the authorization server

resource "okta_auth_server_claim" "auth_claim" {
  name                    = "groups"
  auth_server_id          = okta_auth_server.oidc_auth_server.id
  always_include_in_token = true
  claim_type              = "IDENTITY"
  group_filter_type       = "STARTS_WITH"
  value                   = "ocp-"
  value_type              = "GROUPS"
}

# Add policy and rules to the authorization server

resource "okta_auth_server_policy" "auth_policy" {
  name             = "ocp_policy"
  auth_server_id   = okta_auth_server.oidc_auth_server.id
  description      = "Policy for allowed clients"
  priority         = 1
  client_whitelist = [okta_app_oauth.ocp_oidc.id]
}

resource "okta_auth_server_policy_rule" "auth_policy_rule" {
  name           = "AuthCode + PKCE"
  auth_server_id = okta_auth_server.oidc_auth_server.id
  policy_id      = okta_auth_server_policy.auth_policy.id
  priority       = 1
  grant_type_whitelist = [
    "authorization_code"
  ]
  scope_whitelist = ["*"]
  group_whitelist = ["EVERYONE"]
}