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
variable "name" { default = "" }
variable "source_db_sg_tags" { default = { Type = "Database" } }
variable "db_cluster_size" { default = "1" }
variable "db_engine" { default = "aurora-mysql" }
variable "db_cluster_family" { default = "aurora-mysql5.7" }
variable "db_name" { default = "demo" }
variable "db_user" { default = "demo_user" }
variable "db_password" { default = "Demo_Pass19" }
variable "db_instance_type" { default = "db.t3.small" }
variable "db_cluster_parameters" { default = [] }
variable "db_instance_parameters" { default = [] }

variable "storage_encrypted" { default = false }
variable "kms_key_arn" { default = "" }
variable "db_retention_period" { default = "7" }
variable "db_backup_window" { default = "20:10-20:40" }
variable "db_maintenance_window" { default = "sun:19:00-sun:20:00" }
variable "rds_monitoring_role_arn" { default = "" }
variable "db_enhanced_monitoring" { default = true }
variable "rds_monitoring_interval" { default = "0" }
variable "db_enabled_cloudwatch_logs_exports" { default = ["error","general","slowquery"] }
variable "db_auto_minor_version_upgrade" { default = false }

variable "dns_private" { default = true }
variable "domain_local" { default = "local" }

variable "tags" {
  default = {}
}
