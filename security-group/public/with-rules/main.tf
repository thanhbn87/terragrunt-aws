provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "vpc" {
  tags {
    Name      = "${var.vpc_name}"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.17.0"

  use_name_prefix = false
  name            = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-${lower(var.name)}"
  description     = "${var.description}"
  vpc_id          = "${data.aws_vpc.vpc.id}"

  rules                         = "${var.rules}"
  ingress_cidr_blocks           = "${var.ingress_cidr_blocks}"
  ingress_ipv6_cidr_blocks      = "${var.ingress_ipv6_cidr_blocks}"
  ingress_rules                 = "${var.ingress_rules}"
  ingress_with_cidr_blocks      = "${var.ingress_with_cidr_blocks}"
  ingress_with_ipv6_cidr_blocks = "${var.ingress_with_ipv6_cidr_blocks}"
  ingress_with_self             = "${var.ingress_with_self}"

  egress_cidr_blocks            = "${var.egress_cidr_blocks}"
  egress_ipv6_cidr_blocks       = "${var.egress_ipv6_cidr_blocks}"
  egress_rules                  = "${var.egress_rules}"
  egress_with_cidr_blocks       = "${var.egress_with_cidr_blocks}"
  egress_with_ipv6_cidr_blocks  = "${var.egress_with_ipv6_cidr_blocks}"

  tags = "${merge(var.tags, map("Env", "${var.project_env}", "Namespace", "${var.namespace}"))}"
}
