output "machine_cidr" {
    value = module.vpc.vpc_cidr_block
    description = "For use as '--machine-cidr' parameter in rosa command"
}

output "public_subnet_ids" {
    value = join(",", module.vpc.public_subnets)
}

output "private_subnet_ids" {
    value = join(",", module.vpc.private_subnets)
}

output "all_subnets" {
    value = join(",", concat(module.vpc.private_subnets, module.vpc.public_subnets))
    description = "For use as '--subnet-ids' parameter in rosa command"
}

output "cluster_id" {
    value = shell_script.rosa_sts_public.output["id"]
}

output "cluster_api_url" {
    value = jsondecode(shell_script.rosa_sts_public.output["api"]).url
}

output "cluster_console_url" {
    value = jsondecode(shell_script.rosa_sts_public.output["console"]).url
}