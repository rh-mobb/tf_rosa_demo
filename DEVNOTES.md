# Developer Notes

At some point this will become the README for the entire repo and the BYOVPC example will be split out onto its own.

Writing a TF provider the "good" way for ROSA is going to be difficult for a few reasons:

- It involves creating resources across both the AWS and OpenShift Managed APIs
- The OCM API itself calls another tool that uses Terraform (poorly) to build a bunch of AWS stuff
- Getting a built cluster involves a few resources that can't necessarily be built serially, (e.g., you have to create a cluster in the API before you provision an OIDC provider against it, but actually building the cluster can't proceed until the OIDC provider exists)

So the workaround is to use the `shell` provider and make everything look right in terms of state so TF can manage the lifecycle by remotely controlling the CLI.

## Layout

The general pattern for script directories should look like this:

```
|- [:provider_name[rosa|aro]]
    |- [:resource_type[cluster|sts_cluster|idp|etc]]
```

## Input validation

This isn't just about the values themselves but how they're combined. Unfortunately, this will probably mean re-creating a bunch of validation that already lives in the `rosa` command but just in a more informative way.

### Validation rules

`--multi-az` should map to designation of:
    - 6 subnet IDs if it's a public cluster ()
## Challenges

1. [X] Any customer using TF is going to want to provision their own VPC/network resources/etc. These resources will have state already by the time the ROSA TF gets called. The parameters passed to ROSA include the AWS subnet ID(s), and the ROSA CLI tool uses TF behidn the scenes to build on top of them. But it *also* tags those resources, and those tags are part of how ROSA gets managed (i.e., they have to be there). So to avoid issues with TF running again and seeing tags it didn't provision and removing them, there's a facility in TF that allows tags to be specifically ignored based on either a full string match or a prefix that looks like this:

    ```hcl
    provider "aws" {
        ...

        ignore_tags {
            key_prefixes = ["kubernetes.io/"]
        }
    }
    ```

    Note that this block goes in the provider config, so any tag that starts with "kubernetes.io" that the provisioner touches will be ignored.

1. 


## Authorization against OCM

The `rosa` CLI tool is unable to add an IDP configuration in non-interactive mode, it will always require user input. In a Terraform situation, this is a real blocker to "workload ready cluster".

The alternative is to use the OCM API.

```json
{
    "kind": "IdentityProvider",
    "type": "OpenIDIdentityProvider",
    "href": "/api/clusters_mgmt/v1/clusters/1t3ou594g282sado8cqn0b69lcpabkoe/identity_providers/1t3qgn286ke2u3c94ik0lc1qd11dbeds",
    "id": "1t3qgn286ke2u3c94ik0lc1qd11dbeds",
    "name": "okta-2",
    "mapping_method": "claim",
    "open_id": {
        "claims": {
            "email": [
                "email"
            ],
            "name": [
                "name",
                "email"
            ],
            "preferred_username": [
                "perferred_username",
                "email"
            ]
        },
        "client_id": "0oa5kkh8zda1K6iyQ5d7",
        "client_secret": ""
        "extra_scopes": [
            "email",
            "profile"
        ],
        "issuer": "https://dev-34242021.okta.com"
    }
}
```

```json
{
  "kind": "string",
  "id": "string",
  "href": "string",
  "challenge": true,
  "login": true,
  "mapping_method": "add",
  "name": "string",
  "open_id": {
    "claims": {
      "email": [
        "string"
      ],
      "groups": [
        "string"
      ],
      "name": [
        "string"
      ],
      "preferred_username": [
        "string"
      ]
    },
    "client_id": "string",
    "client_secret": "string",
    "extra_authorize_parameters": {
      "additionalProp1": "string",
      "additionalProp2": "string",
      "additionalProp3": "string"
    },
    "extra_scopes": [
      "string"
    ],
    "issuer": "string"
  },
  "type": "LDAPIdentityProvider"
}