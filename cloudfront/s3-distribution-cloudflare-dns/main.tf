provider "aws" {
  region  = "us-east-1"
  profile = "${var.aws_profile}"
}

provider "cloudflare" {
  email   = "${var.cf_email}"
  token   = "${var.cf_token}"
}

provider "aws" {
  alias   = "s3"
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

  aliases = [ "${split(",", length(var.aliases) == 0 ? join(",", formatlist("%s.${var.root_domain}", var.sub_dns_names)) : join(",", var.aliases))}" ]
  cf_ttl = "${var.cf_proxied ? 1 : var.cf_ttl }"
}

data "aws_s3_bucket" "this" {
  provider = "aws.s3"
  bucket = "${var.s3_bucket == "" ? "${lower(var.project_env_short)}-${lower(var.s3_type)}-${lower(var.domain_name)}" : "${var.s3_bucket}" }"
}

data "aws_acm_certificate" "this" {
  domain   = "${var.domain_name}"
  statuses = ["ISSUED"]
  most_recent = true
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "${lower(var.project_env)}-cloudfront-access-identity"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = "${var.enabled}"
  price_class         = "${var.price_class}"
  is_ipv6_enabled     = "${var.is_ipv6_enabled}"
  default_root_object = "${var.default_root_object}"
  aliases             = ["${local.aliases}"]
  tags                = "${merge(local.common_tags, var.tags)}"

  origin {
    domain_name = "${data.aws_s3_bucket.this.bucket_regional_domain_name}"
    origin_id   = "${lower(var.project_env)}-${lower(var.project_name)}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path}"
    }
  }

  restrictions {
    geo_restriction {
      locations        = "${var.geo_restriction_location}"
      restriction_type = "${var.geo_restriction_type}"
    }
  }
  
  default_cache_behavior {
    allowed_methods        = "${var.default_allowed_methods}"
    cached_methods         = "${var.default_cached_methods}"
    compress               = "${var.default_compress}"
    target_origin_id       = "${lower(var.project_env)}-${lower(var.project_name)}"
    min_ttl                = "${var.min_ttl}"
    default_ttl            = "${var.default_ttl}"
    max_ttl                = "${var.max_ttl}"
    viewer_protocol_policy = "${var.viewer_protocol_policy}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = "${var.cloudfront_default_certificate}"
    acm_certificate_arn            = "${data.aws_acm_certificate.this.arn}"
    ssl_support_method             = "${var.ssl_support_method}"
    minimum_protocol_version       = "${var.minimum_protocol_version}"
  }

  custom_error_response = ["${var.custom_error_response}"]
}

data "aws_iam_policy_document" "s3_policy" {
  provider = "aws.s3"
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.this.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${data.aws_s3_bucket.this.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.this.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  provider = "aws.s3"
  bucket = "${data.aws_s3_bucket.this.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}

/// DNS setting:
resource "cloudflare_record" "this" {
  count   = "${length(var.sub_dns_names)}"
  domain  = "${var.root_domain}"
  name    = "${element(var.sub_dns_names,count.index) == "" ? "@" : "${element(var.sub_dns_names,count.index)}" }"
  value   = "${aws_cloudfront_distribution.this.domain_name}"
  type    = "CNAME"
  ttl     = "${local.cf_ttl}"
  proxied = "${var.cf_proxied}"
}
