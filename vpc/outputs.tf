# VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.vpc.public_subnets}"]
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = ["${module.vpc.database_subnets}"]
}

# ssh key:
output "key_name" {
  description = "The SSH key name"
  value       = "${element(concat(aws_key_pair.key_ssh.*.key_name,list("")),0)}"
}


# route53:
output "private_zone_id" {
  description = "The ID of the Route53 private zone"
  value       = "${element(concat(aws_route53_zone.private.*.zone_id,list("")),0)}"
}

output "public_zone_id" {
  description = "The ID of the Route53 public zone"
  value       = "${element(concat(aws_route53_zone.public.*.zone_id,list("")),0)}"
}

output "public_name_servers" {
  description = "The list NS records of the Route53 public zone"
  value       = "${compact(concat(aws_route53_zone.public.0.name_servers,list("")))}"
}
