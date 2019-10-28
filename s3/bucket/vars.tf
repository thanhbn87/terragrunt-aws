variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "bucket" { default = "" }
variable "type" { default = "asset" }
variable "domain_name" { default = "example.com" }
variable "acl" { default = "private" }

variable "policy" {
  description = "A valid bucket policy JSON document."
  type        = "string"
  default     = ""
}

variable "tags" {
  default = {}
}
