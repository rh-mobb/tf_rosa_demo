module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "thatcher-test"
  cidr = "10.66.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.66.1.0/24", "10.66.2.0/24", "10.66.3.0/24"]
  public_subnets  = ["10.66.101.0/24", "10.66.102.0/24", "10.66.103.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Terraform = "true"
    Environment = "dev"
    Owner = "thhubbar@redhat.com"
  }
}