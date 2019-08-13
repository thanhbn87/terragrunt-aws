provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_ami" "amazon2" {
  owners      = ["137112412989"]
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "${var.tfstate_bucket}"
    key            = "${var.tfstate_key_vpc}"
    region         = "${var.tfstate_region}"
    profile        = "${var.tfstate_profile}"
    role_arn       = "${var.tfstate_arn}"
  }
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_name}"
  }

  subnet_id = "${var.subnet_id == "" ? data.terraform_remote_state.vpc.public_subnets[0] : var.subnet_id }"
  key_name  = "${var.key_name == "" ? data.terraform_remote_state.vpc.key_name : var.key_name }"
  ami       = "${var.ami == "" ? data.aws_ami.amazon2.id : var.ami }"
}

data "aws_security_group" "ec2" {
  tags = "${var.source_ec2_sg_tags}"
}

module "ec2" {
  source  = "thanhbn87/ec2-bastion/aws"
  version = "0.1.0"

  name          = "${var.name}"
  namespace     = "${var.namespace}"
  instance_type = "${var.instance_type}"
  ami           = "${local.ami}"

  delete_on_termination = "${var.delete_on_termination}"
  volume_size           = "${var.volume_size}"
  ebs_optimized         = "${var.ebs_optimized}"

  key_name                    = "${local.key_name}"
  vpc_security_group_ids      = ["${data.aws_security_group.ec2.id}"]
  subnet_id                   = ["${local.subnet_id}"]
  iam_instance_profile        = "${var.iam_instance_profile}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  protect_termination         = "${var.protect_termination}"
  
}

## DNS local:
resource "aws_route53_record" "ec2" {
  count   = "${var.dns_private ? 1 : 0}"
  zone_id = "${data.terraform_remote_state.vpc.private_zone_id}"
  name    = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-${lower(var.project_name)}-${lower(var.name)}.${var.domain_local}"
  type    = "A"
  ttl     = "60"
  records = ["${module.ec2.bastion_eip_private}"]
}
