variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "name" { default = "asset" }
variable "domain_name" { default = "example.com" }
variable "acl" { default = "private" }

variable "tags" {
  default = {}
}
