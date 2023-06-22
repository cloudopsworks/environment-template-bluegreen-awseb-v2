##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_route53_zone" "failover_app_domain" {
  name = var.app_domain_name
}

resource "aws_route53_record" "failover_record" {
  count = var.failover_enabled && !var.app_domain_disabled && !(var.deployment_a_deactivated && var.deployment_b_deactivated) && var.load_balancer_public ? 1 : 0

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

resource "aws_route53_record" "failover_record_internal" {
  count = var.failover_enabled && !var.app_domain_disabled && !(var.deployment_a_deactivated && var.deployment_b_deactivated) && !var.load_balancer_public ? 1 : 0

  name    = format("%s.%s", var.failover_domain_alias, var.app_domain_name)
  type    = "A"
  zone_id = data.aws_route53_zone.failover_app_domain.id

  failover_routing_policy {
    type = upper(var.failover_type)
  }
  set_identifier  = format("%s-%s-%s", var.release_name, var.namespace, var.region)
  health_check_id = aws_route53_health_check.health_all[0].id

  alias {
    name                   = try(module.app_dns_a[0].fqdn, module.app_dns_b[0].fqdn, "")
    zone_id                = data.aws_route53_zone.failover_app_domain.id
    evaluate_target_health = true
  }
}

locals {
  health_check_ids = compact([can(aws_route53_health_check.health_a[0].id) ? aws_route53_health_check.health_a[0].id : null, can(aws_route53_health_check.health_b[0].id) ? aws_route53_health_check.health_b[0].id : null])
}

resource "aws_route53_health_check" "health_all" {
  depends_on = [aws_route53_health_check.health_a, aws_route53_health_check.health_b]
  count      = var.failover_enabled && !var.app_domain_disabled && !(var.deployment_a_deactivated && var.deployment_b_deactivated) && !var.load_balancer_public ? 1 : 0

  type                   = "CALCULATED"
  child_health_threshold = 1
  child_healthchecks     = local.health_check_ids

  tags = merge({
    Name = format("HealthCheck-%s-%s-%s", var.region, var.release_name, var.namespace)
    },
  local.tags)
}

resource "aws_route53_health_check" "health_a" {
  count = var.failover_enabled && !var.app_domain_disabled && !var.deployment_a_deactivated && !var.load_balancer_public ? 1 : 0

  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.metric_alarm_a[0].alarm_name
  cloudwatch_alarm_region         = var.region
  insufficient_data_health_status = "Unhealthy"

  tags = merge({
    Name = format("HealthCheck-%s-%s-%s-%s", var.region, var.release_name, var.namespace, "a")
    },
  local.tags)
}

resource "aws_route53_health_check" "health_b" {
  count = var.failover_enabled && !var.app_domain_disabled && !var.deployment_b_deactivated && !var.load_balancer_public ? 1 : 0

  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.metric_alarm_b[0].alarm_name
  cloudwatch_alarm_region         = var.region
  insufficient_data_health_status = "Unhealthy"

  tags = merge({
    Name = format("HealthCheck-%s-%s-%s-%s", var.region, var.release_name, var.namespace, "b")
    },
  local.tags)
}