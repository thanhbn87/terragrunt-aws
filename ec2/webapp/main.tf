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

  dynamic_subnets  = [ "${split(",", var.in_public ? join(",", data.terraform_remote_state.vpc.public_subnets) : join(",", data.terraform_remote_state.vpc.private_subnets))}" ]
  subnets          = [ "${split(",", length(var.subnets) == 0 ? join(",", local.dynamic_subnets) : join(",", var.subnets))}" ]
  key_name = "${var.key_name == "" ? data.terraform_remote_state.vpc.key_name : var.key_name }"
  ami      = "${var.ami == "" ? data.aws_ami.amazon2.id : var.ami }"
}

data "aws_security_group" "ec2" {
  tags = "${merge(var.source_ec2_sg_tags, map("Env", "${var.project_env}"))}"
}

module "ec2" {
  source  = "thanhbn87/ec2-webapp/aws"
  version = "0.1.2"

  count         = "${var.instance_size}"
  name          = "${var.name}"
  namespace     = "${var.namespace}"
  instance_type = "${var.instance_type}"
  ami           = "${local.ami}"
  project_env   = "${var.project_env}"
  project_env_short   = "${var.project_env_short}"
  ec2_autorecover     = "${var.ec2_autorecover}"

  delete_on_termination = "${var.delete_on_termination}"
  volume_size           = "${var.volume_size}"
  ebs_optimized         = "${var.ebs_optimized}"

  key_name                    = "${local.key_name}"
  vpc_security_group_ids      = ["${data.aws_security_group.ec2.id}"]
  subnets                     = ["${local.subnets}"]
  iam_instance_profile        = "${var.iam_instance_profile}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  protect_termination         = "${var.protect_termination}"
  
}

## DNS local:
resource "aws_route53_record" "ec2" {
  count   = "${var.dns_private ? var.instance_size : 0}"
  zone_id = "${data.terraform_remote_state.vpc.private_zone_id}"
  name    = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-${lower(var.name)}-${format("%02d", count.index + 1)}.${var.domain_local}"
  type    = "A"
  ttl     = "60"
  records = ["${element(module.ec2.private_ips,count.index)}"]
}
