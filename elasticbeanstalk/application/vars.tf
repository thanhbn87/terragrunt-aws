variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "namespace" { default = "" }
variable "name" { default = "webapp" }
variable "description" { default = "The demo ElasticBeanstak App" }
variable "tags" {
  default = {}
}
