variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "domain_name" { default = "example.com" }
variable "s3_type" { default = "asset" }
variable "s3_bucket" { default = "" }

variable "enabled" { default = true }
variable "is_ipv6_enabled" { default = true }
variable "price_class" { default = "PriceClass_200" }
variable "default_root_object" { default = "index.html" }
variable "aliases" { default = [] }
variable "default_allowed_methods" { default = ["GET", "HEAD"] }
variable "default_cached_methods" { default = ["GET", "HEAD"] }
variable "default_compress" { default = true }
variable "min_ttl" { default = "0" }
variable "default_ttl" { default = "86400" }
variable "max_ttl" { default = "31536000" }

variable "geo_restriction_location" { default = [] }
variable "geo_restriction_type" { default = "none" }

variable "viewer_protocol_policy" { default = "redirect-to-https" }
variable "cloudfront_default_certificate" { default = false }
variable "minimum_protocol_version" { default = "TLSv1" }
variable "ssl_support_method" { default = "sni-only" }
variable "custom_error_response" { default = [] }

variable "tags" {
  default = {}
}
