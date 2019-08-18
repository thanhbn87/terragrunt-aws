variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }
variable "namespace" { default = "" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }
variable "cf_email" { default = "admin@example.com" }
variable "cf_token" {}

variable "domain_name" { default = "example.com" }
variable "root_domain" { default = "example.com" }
variable "subject_name" { default = "" }
variable "sub_dns_names" { default = [] }
variable "just_one_name" { default = false }
variable "cdn_cert" { default = false }
variable "cloudflare_record" { default = true }

variable "tags" {
  default = {}
}
