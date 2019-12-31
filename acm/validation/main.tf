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
    Name = "${var.project_name}"
  }
}

///////////////////////////////////
//            Certs              //
///////////////////////////////////
data "aws_route53_zone" "cert" {
  name         = "${var.domain_name}"
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name = "${var.domain_name}"
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method = "DNS"
  tags = "${merge(local.common_tags, var.tags)}"
}

resource "aws_route53_record" "cert_validation" {
  count   = "${var.route53_record ? 1 : 0}"
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.cert.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
  allow_overwrite = "${var.allow_overwrite}"
}

resource "aws_acm_certificate_validation" "cert" {
  count   = "${var.route53_record ? 1 : 0}"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.*.fqdn}"]
}
