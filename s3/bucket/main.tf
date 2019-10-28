provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

locals {
  bucket = "${var.bucket == "" ? "${lower(var.project_env_short)}-${lower(var.type)}-${lower(var.domain_name)}" : var.bucket}"
  common_tags = {
    Env  = "${var.project_env}"
  }
}

///////////////
//     S3    //
///////////////
resource "aws_s3_bucket" "this" {
  bucket = "${local.bucket}"
  acl    = "${var.acl}"
  tags   = "${merge(local.common_tags, var.tags)}"
  
  policy = "${var.policy}"
}
