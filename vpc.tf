module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs_public

  private_subnets      = [for k, v in local.azs_private : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets       = [for k, v in local.azs_public : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  tags                 = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id
  endpoints = { for service in toset(["ssm", "ssmmessages", "ec2messages"]) :
    replace(service, ".", "_") =>
    {
      service             = service
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "${local.name}-${service}" }
    }
  }
  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  tags = local.tags
}

# data "aws_nat_gateway" "default" {
#   vpc_id     = module.vpc.vpc_id
#   depends_on = [module.vpc]
# }

# data "aws_route_table" "ec2" {
#   subnet_id = module.vpc.private_subnets[0]
# }

# resource "aws_route" "egress_ec2_to_internet" {
#   route_table_id         = data.aws_route_table.ec2.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = data.aws_nat_gateway.default.id
# }
