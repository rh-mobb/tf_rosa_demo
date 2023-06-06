module "rosa-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = var.cluster_name
  cidr = var.machine_cidr_block

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true

  # tags = {
  #   Terraform = "true"
  #   Environment = "dev"
  #   Owner = "thhubbar@redhat.com"
  # }
}
