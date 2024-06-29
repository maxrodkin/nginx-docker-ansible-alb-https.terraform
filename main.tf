data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

locals {
  name        = "rodkin-test"
  vpc_cidr    = "10.0.0.0/16"
  azs_private = slice(data.aws_availability_zones.available.names, 0, 1)
  azs_public  = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  }
}

module "ec2_nginx" {
  count = 3

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name                        = "${local.name}-nginx-${count.index}"
  instance_type               = "t2.micro"
  subnet_id                   = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.security_group_instance.security_group_id] #, module.security_group_ssh.security_group_id]
  user_data                   = data.cloudinit_config.nginx.rendered
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2RoleforSSM          = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  }
  key_name = module.key_pair.key_pair_name
  tags     = local.tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name           = "ansible"
  create_private_key = true
}

resource "local_file" "pem" {
  content  = module.key_pair.private_key_pem
  filename = "${path.module}/ansible.pem"
}


module "ec2_ansible" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name                        = "${local.name}-ansible"
  instance_type               = "t2.micro"
  subnet_id                   = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.security_group_instance.security_group_id]
  user_data                   = data.cloudinit_config.ansible.rendered
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2RoleforSSM          = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  }

  tags = local.tags
}

module "security_group_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-ec2"
  description = "Security Group for EC2 Instance Egress"

  vpc_id = module.vpc.vpc_id
  #internet
  egress_rules = ["https-443-tcp", "all-icmp"]

  #inner trafic
  ingress_with_self = [
    {
      rule = "all-tcp"
    },
  ]
  #inner trafic
  egress_with_self = [
    {
      rule = "all-tcp"
    },
  ]
  #access from ALB
  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.security_group_lb.security_group_id
    },
  ]
}
