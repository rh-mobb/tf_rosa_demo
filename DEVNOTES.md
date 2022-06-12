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