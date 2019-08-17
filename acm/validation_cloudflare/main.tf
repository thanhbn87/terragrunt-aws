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

  subject_name              = "${var.subject_name == "" ? var.domain_name : var.subject_name }"
  subject_alternative_names = [ "${split(",", length(var.subject_alternative_names) == 0 ? join(",", list("*.${var.domain_name}")) : join(",", var.subject_alternative_names))}" ]
}

///////////////////////////////////
//            Certs              //
///////////////////////////////////
resource "aws_acm_certificate" "cert" {
  domain_name = "${local.subject_name}"
  subject_alternative_names = ["${local.subject_alternative_names}"]
  validation_method = "DNS"
  tags = "${merge(local.common_tags, var.tags)}"
}

resource "cloudflare_record" "cert_validation" {
  count  = "${var.cloudflare_record ? "${length(var.subject_alternative_names) == 0 ? 1 : length(var.subject_alternative_names)}" : 0}"
  domain = "${var.root_domain}"
  name   = "${aws_acm_certificate.cert.domain_validation_options.[count.index].resource_record_name}"
  value  = "${aws_acm_certificate.cert.domain_validation_options.[count.index].resource_record_value}"
  type   = "CNAME"
  ttl    = 1
}

resource "aws_acm_certificate_validation" "cert" {
  count  = "${var.cloudflare_record ? 1 : 0}"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${cloudflare_record.cert_validation.*.hostname}"]
}
