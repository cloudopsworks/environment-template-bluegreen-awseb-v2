##
# (c) 2021-2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

##
# This module to manage DNS association.
#   - This can be commented out to disable DNS management (not recommended)
#
module "app_dns_b" {
  count = !var.app_domain_disabled && !var.deployment_b_deactivated && !var.load_balancer_shared ? 1 : 0

  source          = "cloudopsworks/beanstalk-dns/aws"
  version         = "1.0.5"
  region          = var.region
  sts_assume_role = var.sts_assume_role

  release_name             = var.release_name_b
  namespace                = format("%s-%s", var.namespace, "b")
  private_domain           = var.app_domain_private
  domain_name              = var.app_domain_name
  domain_name_alias_prefix = var.app_domain_alias
  domain_name_weight       = var.deployment_traffic == "b" ? 10 : 0
  default_domain_ttl       = var.app_domain_ttl
  domain_alias             = true
  alias_cname              = module.beanstalk_app_b[0].environment_cname
  alias_zone_id            = module.beanstalk_app_b[0].environment_zone_id
  #health_check_id          = try(aws_route53_health_check.health_a[0].id, "")
}

module "app_version_b" {
  count = !var.deployment_b_deactivated ? 1 : 0

  source          = "cloudopsworks/beanstalk-version/aws"
  version         = "1.0.10"
  region          = var.region
  sts_assume_role = var.sts_assume_role

  release_name     = var.release_name_b
  source_name      = var.source_name_b
  source_version   = var.app_version_b
  namespace        = var.namespace
  solution_stack   = var.solution_stack_b
  repository_owner = var.repository_owner
  # For the sake of the version consistency hash is maintained off the module
  config_source_folder = "values/${var.release_name_b}"
  config_hash_file     = "${path.root}/.values_hash_b"
  bluegreen_identifier = "b"
  #   Supported source_compressed_type: zip, tar, tar.gz, tgz, tar.bz, tar.bz2, etc.
  force_source_compressed = var.source_force_compressed
  source_compressed_type  = var.source_compressed_type

  application_versions_bucket = local.application_versions_bucket

  beanstalk_application = var.beanstalk_application

  github_package = var.gh_package_b
  package_name   = var.gh_package_name_b
  package_type   = var.gh_package_type_b

  depends_on = [
    module.versions_bucket
  ]
}

module "beanstalk_app_b" {
  count = !var.deployment_b_deactivated ? 1 : 0

  source          = "cloudopsworks/beanstalk-deploy/aws"
  version         = "1.0.15"
  region          = var.region
  sts_assume_role = var.sts_assume_role

  release_name              = var.release_name_b
  namespace                 = format("%s-%s", var.namespace, "b")
  solution_stack            = var.solution_stack_b
  application_version_label = module.app_version_b[0].application_version_label

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  vpc_id          = var.vpc_id
  server_types    = var.server_types


  beanstalk_application          = var.beanstalk_application
  beanstalk_ec2_key              = var.beanstalk_ec2_key
  beanstalk_ami_id               = var.beanstalk_ami_id
  beanstalk_instance_port        = var.beanstalk_instance_port
  beanstalk_enable_spot          = var.beanstalk_enable_spot
  beanstalk_default_retention    = var.beanstalk_default_retention
  beanstalk_instance_volume_size = var.beanstalk_instance_volume_size
  beanstalk_instance_volume_type = var.beanstalk_instance_volume_type
  beanstalk_instance_profile     = var.beanstalk_instance_profile
  beanstalk_service_role         = var.beanstalk_service_role
  beanstalk_min_instances        = var.beanstalk_min_instances
  beanstalk_max_instances        = var.beanstalk_max_instances
  beanstalk_lb_sg                = var.beanstalk_lb_sg
  beanstalk_target_sg            = var.beanstalk_target_sg

  load_balancer_shared             = var.load_balancer_shared
  load_balancer_shared_name        = var.load_balancer_shared_name
  load_balancer_shared_weight      = var.deployment_traffic == "b" ? 10 : 0
  load_balancer_public             = var.load_balancer_public
  load_balancer_log_bucket         = local.load_balancer_log_bucket
  load_balancer_log_prefix         = "${var.release_name_b}-b"
  load_balancer_ssl_certificate_id = var.load_balancer_ssl_certificate_id
  load_balancer_ssl_policy         = var.load_balancer_ssl_policy
  load_balancer_alias              = var.load_balancer_alias == "" ? format("%s-%s-%s", var.release_name_b, var.namespace, "b") : format("%s-%s", var.load_balancer_alias, "b")

  port_mappings  = var.beanstalk_port_mappings
  rule_mappings  = [] #var.beanstalk_rule_mappings
  extra_settings = var.extra_settings
  extra_tags     = merge(var.extra_tags, module.tags.locals.common_tags)
}
