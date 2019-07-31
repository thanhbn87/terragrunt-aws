provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_availability_zones" "available" {}

locals {
  common_tags = {
    Env = "${var.project_env}"
  }
}

///////////////////////
//        vpc        //
///////////////////////

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.67.0"

  name = "${var.vpc_name == "" ? "${var.project_env}-${var.project_name}" : "${var.vpc_name}" }"
  cidr = "${var.vpc_cidr}"

  enable_dns_hostnames    = "${var.enable_dns_hostnames}"
  enable_dns_support      = "${var.enable_dns_support}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  enable_nat_gateway      = "${var.enable_nat_gateway}"
  single_nat_gateway      = "${var.single_nat_gateway}"

  azs                     = ["${data.aws_availability_zones.available.names[0]}",
                             "${data.aws_availability_zones.available.names[1]}",
                             "${data.aws_availability_zones.available.names[2]}"]

  public_subnets          = ["${cidrsubnet("${var.vpc_cidr}", 3, 1)}",
                             "${cidrsubnet("${var.vpc_cidr}", 3, 2)}"]
  private_subnets         = ["${cidrsubnet("${var.vpc_cidr}", 3, 3)}",
                             "${cidrsubnet("${var.vpc_cidr}", 3, 4)}"]
  database_subnets        = ["${cidrsubnet("${cidrsubnet("${var.vpc_cidr}", 3, 5)}", 2, 0)}",
                             "${cidrsubnet("${cidrsubnet("${var.vpc_cidr}", 3, 5)}", 2, 1)}",
                             "${cidrsubnet("${cidrsubnet("${var.vpc_cidr}", 3, 5)}", 2, 2)}"]

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "${var.domain_local}"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]
  create_database_subnet_group     = "${var.create_database_subnet_group}"

  tags = "${merge(local.common_tags, var.tags)}"

}

///////////////////////////////////
//           Endpoint            //
///////////////////////////////////
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = "${module.vpc.vpc_id}"
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = ["${concat(module.vpc.private_route_table_ids,module.vpc.public_route_table_ids)}"]
}

///////////////////////////////////
//            Route53            //
///////////////////////////////////
resource "aws_route53_zone" "private" {
  count   = "${var.dns_private ? 1 : 0}"
  name    = "${var.domain_local}"
  comment = "${var.project_name} Private Zone"

  vpc {
    vpc_id  = "${module.vpc.vpc_id}"
  }

  tags = "${merge(local.common_tags, var.tags)}"
}

resource "aws_route53_zone" "public" {
  count   = "${var.dns_public ? 1 : 0}"
  name    = "${var.domain_name}"
  comment = "${var.project_name} Public Zone"

  tags = "${merge(local.common_tags, var.tags)}"
}

///////////////////////
//       Keys        //
///////////////////////
resource "aws_key_pair" "key_ssh" {
  count      = "${var.add_key_pair ? 1 : 0}"
  key_name   = "${var.project_name}-${var.project_env}"
  public_key = "${file("${var.ssh_public_key}")}"
}
