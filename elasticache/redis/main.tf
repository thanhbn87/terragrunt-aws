provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_availability_zones" "available" {}

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

data "aws_security_group" "cache" {
  tags = "${var.source_sg_tags}"
  tags = "${merge(var.source_sg_tags, map("Env", "${var.project_env}"))}"
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_name}"
  }
}

# main module:
module "redis" {
  source  = "github.com/thanhbn87/terraform-aws-elasticache-redis.git?ref=common"
  //source = "/home/thanhbn/WorkSpace/myRepos/myGithub//terraform-aws-elasticache-redis"

  namespace       = "${var.namespace}"
  stage           = "${var.project_env_short}"
  name            = "${var.name == "" ? lower(var.project_name) : lower(var.name)}"

  engine_version  = "${var.redis_version}"
  family          = "${var.redis_family}"
  cluster_size    = "${var.redis_cluster_size}"
  instance_type   = "${var.redis_instance_type}"
  port            = "${var.redis_port}"
  
  vpc_id             = "${data.terraform_remote_state.vpc.vpc_id}"
  security_groups    = ["${data.aws_security_group.cache.id}"]
  subnets            = ["${data.terraform_remote_state.vpc.database_subnets}"]
  availability_zones = [
    "${data.aws_availability_zones.available.names[0]}",
    "${data.aws_availability_zones.available.names[1]}",
    "${data.aws_availability_zones.available.names[2]}"
  ] 
  automatic_failover = "${var.automatic_failover}"

  # Encrypt:
  at_rest_encryption_enabled  = "${var.at_rest_encryption_enabled}"
  transit_encryption_enabled  = "${var.transit_encryption_enabled}"

  # Backup and maintain:
  maintenance_window       = "${var.maintenance_window}"
  snapshot_window          = "${var.backup_window}"
  snapshot_retention_limit = "${var.backup_retention_limit}"

  # Notification:
  notification_topic_arn = "${var.notification_topic_arn}"
}

## DNS local:
resource "aws_route53_record" "redis_writer" {
  count   = "${var.dns_private ? 1 : 0}"
  zone_id = "${data.terraform_remote_state.vpc.private_zone_id}"
  name    = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-redis-writer.${var.domain_local}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${module.redis.host}"]
}
