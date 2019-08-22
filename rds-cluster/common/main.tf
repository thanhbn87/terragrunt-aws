provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
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

data "aws_security_group" "db" {
  tags = "${merge(var.source_db_sg_tags, map("Env", "${var.project_env}"))}"
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_name}"
  }

  rds_monitoring_role_arn = "${var.db_enhanced_monitoring && var.rds_monitoring_role_arn == "" ? element(concat(aws_iam_role.enhanced_monitoring.*.arn,list("")),0) : var.rds_monitoring_role_arn }"
  rds_monitoring_interval = "${var.db_enhanced_monitoring && var.rds_monitoring_interval == 0 ? 60 : var.rds_monitoring_interval }"
}

# enhanced_monitoring
data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    actions = [ "sts:AssumeRole" ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  count              = "${var.db_enhanced_monitoring ? 1 : 0}"
  name               = "rds-monitoring-role"
  assume_role_policy = "${data.aws_iam_policy_document.enhanced_monitoring.json}"
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count      = "${var.db_enhanced_monitoring ? 1 : 0}"
  role       = "${aws_iam_role.enhanced_monitoring.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# main module:
module "aurora" {
  //source  = "github.com/thanhbn87/terraform-aws-rds-cluster.git?ref=common"
  source  = "thanhbn87/rds-cluster/aws"
  version = "0.15.1"

  engine          = "${var.db_engine}"
  cluster_family  = "${var.db_cluster_family}"
  cluster_size    = "${var.db_cluster_size}"
  namespace       = "${var.namespace}"
  stage           = "${var.project_env_short}"
  name            = "${var.name == "" ? lower(var.project_name) : lower(var.name)}"
  admin_user      = "${var.db_user}"
  admin_password  = "${var.db_password}"
  db_name         = "${var.db_name}"
  instance_type   = "${var.db_instance_type}"
  vpc_id          = "${data.terraform_remote_state.vpc.vpc_id}"
  security_groups = ["${data.aws_security_group.db.id}"]
  subnets         = ["${data.terraform_remote_state.vpc.database_subnets}"]

  cluster_parameters  = ["${var.db_cluster_parameters}"]
  instance_parameters = ["${var.db_instance_parameters}"]

  # Encrypt:
  storage_encrypted  = "${var.storage_encrypted}"
  kms_key_arn        = "${var.kms_key_arn}"

  # Backup and maintain:
  retention_period   = "${var.db_retention_period}"
  backup_window      = "${var.db_backup_window}"
  maintenance_window = "${var.db_maintenance_window}"

  # Monitor:
  rds_monitoring_interval = "${local.rds_monitoring_interval}"
  rds_monitoring_role_arn = "${local.rds_monitoring_role_arn}"

  # Log to cloudwatch:
  enabled_cloudwatch_logs_exports = "${var.db_enabled_cloudwatch_logs_exports}"

  # Minor update:
  auto_minor_version_upgrade = "${var.db_auto_minor_version_upgrade}"
}

## DNS local:
resource "aws_route53_record" "db_writer" {
  count   = "${var.dns_private ? 1 : 0}"
  zone_id = "${data.terraform_remote_state.vpc.private_zone_id}"
  name    = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-rds-"${var.name == "" ? "" : "${lower(var.name)}-"}"writer.${var.domain_local}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${module.aurora.endpoint}"]
}

resource "aws_route53_record" "db_reader" {
  count   = "${var.dns_private ? 1 : 0}"
  zone_id = "${data.terraform_remote_state.vpc.private_zone_id}"
  name    = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-rds-reader.${var.domain_local}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${module.aurora.reader_endpoint}"]
}
