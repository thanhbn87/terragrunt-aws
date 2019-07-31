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

///////////////
//     S3    //
///////////////
resource "aws_s3_bucket" "this" {
  bucket = "${lower(var.project_env_short)}-${lower(var.name)}-${lower(var.domain_name)}"
  acl    = "${var.acl}"
  tags   = "${merge(local.common_tags, var.tags)}"
}
