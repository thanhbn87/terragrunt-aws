provider "cloudflare" {
  email = "${var.cf_email}"
  token = "${var.cf_token}"
}

provider "aws" {
  region  = "${var.cdn_cert ? "us-east-1" : "${var.aws_region}" }"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_env}-${var.project_name}"
  }
}

///////////////////////////////////
//            Certs              //
///////////////////////////////////
resource "aws_acm_certificate" "cert" {
  domain_name = "${var.domain_name}"
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method = "DNS"
  tags = "${merge(local.common_tags, var.tags)}"
}

resource "cloudflare_record" "cert_validation" {
  domain = "${var.root_domain}"
  name   = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  value  = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"
  type   = "CNAME"
  ttl    = 1
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${cloudflare_record.cert_validation.hostname}"]
}