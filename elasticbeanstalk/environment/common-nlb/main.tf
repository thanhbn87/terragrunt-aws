provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

provider "cloudflare" {
  email   = "${var.cf_email}"
  token   = "${var.cf_token}"
}

terraform {
  backend "s3" {}
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${var.project_name}"
  }

  webapp_subnets    = [ "${split(",", var.webapp_in_public ? join(",", data.terraform_remote_state.vpc.public_subnets) : join(",", data.terraform_remote_state.vpc.private_subnets))}" ]
  app_name_empty    = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-${lower(var.name)}"
  app_name_notempty = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-${lower(var.app_name)}"
  app_name          = "${var.app_name == "" ? local.app_name_empty : local.app_name_notempty }"
  cf_ttl            = "${var.cf_proxied ? 1 : var.cf_ttl }"
  
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    encrypt        = true
    bucket         = "${var.tfstate_bucket}"
    key            = "${var.tfstate_key_vpc}"
    region         = "${var.tfstate_region}"
    profile        = "${var.tfstate_profile}"
    role_arn       = "${var.tfstate_arn}"
  }
}

data "aws_security_group" "ec2" {
  tags = "${merge(var.source_ec2_sg_tags, map("Env", "${var.project_env}"))}"
}

data "aws_security_group" "bastion" {
  tags = "${merge(var.source_bastion_sg_tags, map("Env", "${var.project_env}"))}"
}

data "aws_route53_zone" "public" {
  count        = "${var.dns_management == "route53" ? 1 : 0 }"
  name         = "${var.domain_name}"
  private_zone = false
}

module "eb_env" {
  #source = "git::https://github.com/thanhbn87/terraform-aws-elastic-beanstalk-environment.git?ref=0.13.2"
  source = "/home/thanhbn/WorkSpace/myRepos/myGithub//terraform-aws-elastic-beanstalk-environment"
  

  name        = "${lower(var.name)}"
  description = "${var.description}"
  stage       = "${lower(var.project_env_short)}"
  namespace   = "${var.namespace}"
  tags        = "${merge(local.common_tags, var.tags)}"
  zone_id     = "${var.zone_id}"
  app         = "${local.app_name}"
  tier        = "${var.tier}"

  ## IAM:
  temp_file_assumerole       = "${var.temp_file_assumerole}"
  temp_file_policy           = "${var.temp_file_policy}"
  iam_instance_profile       = "${var.iam_instance_profile}"
  service_name               = "${var.service_name}"
  ssm_enabled                = "${var.ssm_enabled}"

  ## Software:
  solution_stack_name                = "${var.solution_stack_name}"
  enable_stream_logs                 = "${var.enable_stream_logs}"
  logs_delete_on_terminate           = "${var.logs_delete_on_terminate}"
  logs_retention_in_days             = "${var.logs_retention_in_days}"
  enable_log_publication_control     = "${var.enable_log_publication_control}"
  env_vars                           = "${var.env_vars}"
  nodejs_version                     = "${var.nodejs_version}"

  ## Instance:
  instance_type           = "${var.instance_type}"
  root_volume_size        = "${var.root_volume_size}"
  root_volume_type        = "${var.root_volume_type}"
  security_groups         = ["${data.aws_security_group.ec2.id}"]
  ssh_source_restriction  = "${data.aws_security_group.bastion.id}"

  ## Capacity:
  environment_type        = "${var.environment_type}"
  autoscale_min           = "${var.autoscale_min}"
  autoscale_max           = "${var.autoscale_max}"
  availability_zones      = "${var.availability_zones}"
  
  autoscale_measure_name  = "${var.autoscale_measure_name}"
  autoscale_statistic     = "${var.autoscale_statistic}"
  autoscale_unit          = "${var.autoscale_unit}"
  updating_min_in_service = "${var.updating_min_in_service}"
  updating_max_batch      = "${var.updating_max_batch}"
  
  autoscale_lower_bound     = "${var.autoscale_lower_bound}"
  autoscale_lower_increment = "${var.autoscale_lower_increment}"
  autoscale_upper_bound     = "${var.autoscale_upper_bound}"
  autoscale_upper_increment = "${var.autoscale_upper_increment}"

  ## Load balancer:
  http_listener_enabled               = "${var.http_listener_enabled}"
  
  ## Rolling updates and deployments:
  deploy_policy               = "${var.deploy_policy}"
  rolling_update_type         = "${var.rolling_update_type}"
  updating_min_in_service     = "${var.updating_min_in_service}"
  updating_max_batch          = "${var.updating_max_batch}"
  rolling_update_type         = "${var.rolling_update_type}"

  ## Security:
  keypair                     = "${data.terraform_remote_state.vpc.key_name}"

  ## Monitoring:
  enhanced_reporting_enabled  = "${var.enhanced_reporting_enabled}"
  config_document             = "${var.config_document}"
  force_destroy               = "${var.force_destroy}"

  ## Managed updates:
  enable_managed_actions      = "${var.enable_managed_actions}"
  preferred_start_time        = "${var.preferred_start_time}"
  update_level                = "${var.update_level}"
  instance_refresh_enabled    = "${var.instance_refresh_enabled}"

  ## Notifications:
  notification_endpoint       = "${var.notification_endpoint}"
  notification_protocol       = "${var.notification_protocol}"
  notification_topic_arn      = "${var.notification_topic_arn}"
  notification_topic_name     = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-${lower(var.project_name)}-${lower(var.name)}"

  ## Network:
  vpc_id                      = "${data.terraform_remote_state.vpc.vpc_id}"
  associate_public_ip_address = "${var.webapp_in_public ? true : false}"
  elb_scheme                  = "${var.elb_scheme}"
  public_subnets              = "${data.terraform_remote_state.vpc.public_subnets}"
  private_subnets             = "${local.webapp_subnets}"
}

resource "aws_route53_record" "eb_env" {
  count   = "${var.dns_management == "route53" ? length(var.sub_dns_names) : 0 }"
  zone_id = "${element(concat(data.aws_route53_zone.public.*.id,list("")),0)}"
  name    = "${element(var.sub_dns_names,count.index) == "" ? "${var.domain_name}" : "${element(var.sub_dns_names,count.index)}.${var.domain_name}" }"
  type    = "A"
  
  alias {
    name                   = "${module.eb_env.elb_dns_name}"
    zone_id                = "${module.eb_env.elb_zone_id}"
    evaluate_target_health = true
  }
}

resource "cloudflare_record" "eb_env" {
  count   = "${var.dns_management == "cloudflare" ? length(var.sub_dns_names) : 0 }"
  domain  = "${var.root_domain}"
  name    = "${element(var.sub_dns_names,count.index) == "" ? "@" : "${element(var.sub_dns_names,count.index)}" }"
  value   = "${module.eb_env.elb_dns_name}"
  type    = "CNAME"
  ttl     = "${local.cf_ttl}"
  proxied = "${var.cf_proxied}"
}
