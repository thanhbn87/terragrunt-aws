variable "project_name" { default = "Demo" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "tfstate_bucket" { default = "example-tfstate-bucket" }
variable "tfstate_region" { default = "us-west-2" }
variable "tfstate_profile" { default = "default" }
variable "tfstate_arn" { default = "" }
variable "tfstate_key_vpc" { default = "demo/vpc/terraform.tfstate" }

variable "namespace" { default = "" }
variable "source_sg_tags" { default = { Type = "Cache" } }
variable "redis_cluster_size" { default = "1" }
variable "redis_version" { default = "5.0.4" }
variable "redis_family" { default = "redis5.0" }
variable "redis_instance_type" { default = "cache.t2.micro" }
variable "redis_port" { default = "6379" }

variable "at_rest_encryption_enabled" { default = false }
variable "transit_encryption_enabled" { default = false }
variable "maintenance_window" { default = "sun:19:00-sun:20:00" }
variable "backup_window" { default = "17:15-18:15" }
variable "backup_retention_limit" { default = "7" }
variable "automatic_failover" { default = true }
variable "notification_topic_arn" { default = "" }

variable "dns_private" { default = true }
variable "domain_local" { default = "local" }

variable "tags" {
  default = {}
}
