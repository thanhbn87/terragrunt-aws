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
  namespace   = "${var.namespace == "" ? lower(var.project_name) : lower(var.namespace)}"
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${lower(var.project_env)}-${local.namespace}"
  }

  subject_name = "${var.subject_name == "" ? var.domain_name : var.subject_name }"
  sj_alt_names = [ "${split(",", length(var.sub_dns_names) == 0 ? join(",", list("*.${local.subject_name}")) : join(",", formatlist("%s.${var.root_domain}", var.sub_dns_names)))}" ]
  subject_alternative_names = [ "${compact(split(",", var.just_one_name ? join(",", list("")) : join(",", local.sj_alt_names)))}" ]
}

///////////////////////////////////
//            Certs              //
///////////////////////////////////
resource "aws_acm_certificate" "cert" {
  domain_name = "${local.subject_name}"
  subject_alternative_names = ["${compact(local.subject_alternative_names)}"]
  validation_method = "DNS"
  tags = "${merge(local.common_tags, var.tags)}"
}

resource "cloudflare_record" "cert_validation" {
  count  = "${var.cloudflare_record ? "${var.just_one_name || length(var.sub_dns_names) == 0 ? 1 : length(local.subject_alternative_names)+1 }" : 0}"
  domain = "${var.root_domain}"
  name   = "${lookup(aws_acm_certificate.cert.domain_validation_options[count.index],"resource_record_name")}"
  value  = "${substr("${lookup(aws_acm_certificate.cert.domain_validation_options[count.index],"resource_record_value")}", -1, -1) == "." ? substr("${lookup(aws_acm_certificate.cert.domain_validation_options[count.index],"resource_record_value")}", 0, length("${lookup(aws_acm_certificate.cert.domain_validation_options[count.index],"resource_record_value")}")-1) : "${lookup(aws_acm_certificate.cert.domain_validation_options[count.index],"resource_record_value")}"}"
  type   = "CNAME"
  ttl    = 1
}

resource "aws_acm_certificate_validation" "cert" {
  count  = "${var.cloudflare_record ? 1 : 0}"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${cloudflare_record.cert_validation.*.hostname}"]
}
