variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "enable_dns_hostnames" { default = true }
variable "enable_dns_support" { default = true }
variable "map_public_ip_on_launch" { default = false }
variable "enable_nat_gateway" { default = false }
variable "single_nat_gateway" { default = true }
variable "create_database_subnet_group" { default = false }

variable "domain_name" { default = "example.com" }
variable "dns_public" { default = true }
variable "domain_local" { default = "demo.local" }
variable "dns_private" { default = true }

variable "add_key_pair" { default = true }
variable "ssh_public_key" { default = "~/.ssh/id_rsa.pub" }

variable "tags" {
  default = {}
}
