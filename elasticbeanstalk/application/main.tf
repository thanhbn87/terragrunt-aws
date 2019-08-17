provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_name}"
  }
}

module "eb-app" {
  source  = "cloudposse/elastic-beanstalk-application/aws"
  version = "0.1.6"

  name        = "${lower(var.name)}"
  description = "${var.description}"
  stage       = "${lower(var.project_env_short)}"
  namespace   = "${var.namespace}"
  tags        = "${merge(local.common_tags, var.tags)}"
}
