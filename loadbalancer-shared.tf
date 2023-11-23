##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
# Module to manage the association of the DNS record with the shared load balancer

data "aws_lb" "shared_lb" {
  count = var.load_balancer_shared ? 1 : 0
  name  = var.load_balancer_shared_name
}

module "app_dns_shared" {
  count = !var.app_domain_disabled && var.load_balancer_shared ? 1 : 0

  source          = "cloudopsworks/beanstalk-dns/aws"
  version         = "1.0.4"
  region          = var.region
  sts_assume_role = var.sts_assume_role

  release_name             = var.release_name
  namespace                = var.namespace
  domain_name              = var.app_domain_name
  domain_name_alias_prefix = var.app_domain_alias
  default_domain_ttl       = var.app_domain_ttl
  domain_alias             = true
  alias_cname              = data.aws_lb.shared_lb[0].dns_name
  alias_zone_id            = data.aws_lb.shared_lb[0].zone_id
  #health_check_id          = try(aws_route53_health_check.health_a[0].id, "")
}