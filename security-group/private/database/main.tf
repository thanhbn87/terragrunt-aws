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

data "aws_security_group" "source_sg_01" {
  tags = "${var.source_sg01_tags}"
}

data "aws_security_group" "source_sg_02" {
  tags = "${var.source_sg02_tags}"
}

locals {
  source_sg01_id = "${element(compact(list(var.source_sg01_id, data.aws_security_group.source_sg_01.id, "")), 0)}"
  source_sg02_id = "${element(compact(list(var.source_sg02_id, data.aws_security_group.source_sg_02.id, "")), 0)}"
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.17.0"

  use_name_prefix = false
  name            = "${lower(var.project_env_short)}-${lower(var.name)}"
  description     = "${var.description}"
  vpc_id          = "${data.aws_vpc.vpc.id}"

  rules                         = "${var.rules}"
  ingress_with_cidr_blocks      = "${var.ingress_with_cidr_blocks}"
  ingress_with_ipv6_cidr_blocks = "${var.ingress_with_ipv6_cidr_blocks}"
  ingress_with_self             = "${var.ingress_with_self}"
  ingress_with_source_security_group_id = [
    {
      rule                     = "db-port"
      description              = "${var.db_rule1_desc}"
      source_security_group_id = "${local.source_sg01_id}"
    },
    {
      rule                     = "db-port"
      description              = "${var.db_rule2_desc}"
      source_security_group_id = "${local.source_sg02_id}"
    },
  ] 

  egress_cidr_blocks            = "${var.egress_cidr_blocks}"
  egress_ipv6_cidr_blocks       = "${var.egress_ipv6_cidr_blocks}"
  egress_rules                  = "${var.egress_rules}"
  egress_with_cidr_blocks       = "${var.egress_with_cidr_blocks}"
  egress_with_ipv6_cidr_blocks  = "${var.egress_with_ipv6_cidr_blocks}"

  tags = "${merge(var.tags, map("Env", "${var.project_env}"))}"
}
