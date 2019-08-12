variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }
variable "cf_email" { default = "admin@example.com" }
variable "cf_token" {}

variable "domain_name" { default = "example.com" }
variable "cdn_cert" { default = false }

variable "tags" {
  default = {}
}
