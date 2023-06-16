##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_route53_zone" "failover_app_domain" {
  name = var.app_domain_name
}

resource "aws_route53_record" "failover_record" {
  count = var.failover_enabled && !var.app_domain_disabled && !(var.deployment_a_deactivated && var.deployment_a_deactivated) ? 1 : 0

  name    = format("%s.%s", var.failover_domain_alias, var.app_domain_name)
  type    = "A"
  zone_id = data.aws_route53_zone.failover_app_domain.id

  failover_routing_policy {
    type = upper(var.failover_type)
  }
  set_identifier = format("%s-%s-%s", var.release_name, var.namespace, var.region)

  alias {
    name                   = try(module.app_dns_a[0].fqdn, module.app_dns_b[0].fqdn, "")
    zone_id                = data.aws_route53_zone.failover_app_domain.id
    evaluate_target_health = true
  }
}