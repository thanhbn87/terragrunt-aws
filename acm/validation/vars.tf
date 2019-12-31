variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "domain_name" { default = "example.com" }
variable "cdn_cert" { default = false }
variable "route53_record" { default = true }
variable "allow_overwrite" { default = true }

variable "tags" {
  default = {}
}
