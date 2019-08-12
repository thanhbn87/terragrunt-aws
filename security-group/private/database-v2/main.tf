provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "vpc" {
  tags {
    Name = "${var.vpc_name}"
  }
}

data "aws_security_groups" "source_sg" {
  tags = "${var.source_sg_tags}"
  
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc.id}"]
  }
}

resource "null_resource" "ingress_with_source_sgs" {
  count = "${length(data.aws_security_groups.source_sg.ids)}"

  triggers {
    rule                     = "db-port"
    description              = "${element(data.aws_security_groups.source_sg.ids, count.index)}"
    source_security_group_id = "${element(data.aws_security_groups.source_sg.ids, count.index)}"
  }
}

locals {
  ingress_with_source_sgs = "${null_resource.ingress_with_source_sgs.*.triggers}"
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.17.0"

  use_name_prefix = false
  name            = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-${lower(var.name)}"
  description     = "${var.description}"
  vpc_id          = "${data.aws_vpc.vpc.id}"

  rules                         = "${var.rules}"
  ingress_with_cidr_blocks      = "${var.ingress_with_cidr_blocks}"
  ingress_with_ipv6_cidr_blocks = "${var.ingress_with_ipv6_cidr_blocks}"
  ingress_with_self             = "${var.ingress_with_self}"
  ingress_with_source_security_group_id = "${local.ingress_with_source_sgs}"

  egress_cidr_blocks            = "${var.egress_cidr_blocks}"
  egress_ipv6_cidr_blocks       = "${var.egress_ipv6_cidr_blocks}"
  egress_rules                  = "${var.egress_rules}"
  egress_with_cidr_blocks       = "${var.egress_with_cidr_blocks}"
  egress_with_ipv6_cidr_blocks  = "${var.egress_with_ipv6_cidr_blocks}"

  tags = "${merge(var.tags, map("Env", "${var.project_env}"))}"
}
