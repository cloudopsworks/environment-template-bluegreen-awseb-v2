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



locals {
  sh_rule_mappings_a = {
    for rule in var.beanstalk_rule_mappings :
    "${rule.process}-a" => rule
    if var.load_balancer_shared && !var.deployment_a_deactivated
  }
  sh_rule_mappings_b = {
    for rule in var.beanstalk_rule_mappings :
    "${rule.process}-b" => rule
    if var.load_balancer_shared && !var.deployment_b_deactivated
  }
  sh_port_mappings_a = {
    for port in var.beanstalk_port_mappings :
    "${port.name}-a" => port
    if var.load_balancer_shared && !var.deployment_a_deactivated
  }
  sh_port_mappings_b = {
    for port in var.beanstalk_port_mappings :
    "${port.name}-b" => port
    if var.load_balancer_shared && !var.deployment_b_deactivated
  }
}


data "aws_lb_listener" "shared_lb_listener_a" {
  for_each          = local.sh_rule_mappings_a
  load_balancer_arn = data.aws_lb.shared_lb[0].arn
  port              = local.sh_port_mappings_a[each.key].from_port
}

resource "aws_lb_target_group" "shared_lb_tg_a" {
  for_each = local.sh_rule_mappings_a
  name     = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
  port     = local.sh_port_mappings_a[each.key].to_port
  protocol = local.sh_port_mappings_a[each.key].protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    protocol            = local.sh_port_mappings_a[each.key].backend_protocol
    matcher             = "200-302"
  }

  tags = {
    Name        = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
    Environment = "${var.release_name}-${var.namespace}-shared"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "shared_lb_tg_a_att" {
  for_each               = local.sh_rule_mappings_a
  autoscaling_group_name = module.beanstalk_app_a[0].environment_scaling_groups_ids[0]
  lb_target_group_arn    = aws_lb_target_group.shared_lb_tg_a[each.key].arn
}

resource "aws_lb_listener_rule" "shared_lb_listener_rule_a" {
  for_each     = local.sh_rule_mappings_a
  listener_arn = data.aws_lb_listener.shared_lb_listener_a[each.key].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shared_lb_tg_a[each.key].arn
  }

  condition {
    host_header {
      values = tolist(concat(split(",", each.value.host), [module.beanstalk_app_a[0].environment_cname]))
    }
  }
}

####

data "aws_lb_listener" "shared_lb_listener_b" {
  for_each          = local.sh_rule_mappings_b
  load_balancer_arn = data.aws_lb.shared_lb[0].arn
  port              = local.sh_port_mappings_b[each.key].from_port
}

resource "aws_lb_target_group" "shared_lb_tg_b" {
  for_each = local.sh_rule_mappings_b
  name     = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
  port     = local.sh_port_mappings_b[each.key].from_port
  protocol = local.sh_port_mappings_b[each.key].protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = local.sh_port_mappings_b[each.key].to_port
    protocol            = local.sh_port_mappings_b[each.key].backend_protocol
    matcher             = "200-302"
  }

  tags = {
    Name        = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
    Environment = "${var.release_name}-${var.namespace}-shared"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "shared_lb_tg_b_att" {
  for_each               = local.sh_rule_mappings_b
  autoscaling_group_name = module.beanstalk_app_b[0].environment_scaling_groups_ids[0]
  lb_target_group_arn    = aws_lb_target_group.shared_lb_tg_b[each.key].arn
}

resource "aws_lb_listener_rule" "shared_lb_listener_rule_b" {
  for_each     = local.sh_rule_mappings_b
  listener_arn = data.aws_lb_listener.shared_lb_listener_b[each.key].arn
  priority     = each.value.priority - (var.deployment_traffic == "b" ? 10 : -1)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shared_lb_tg_b[each.key].arn
  }

  condition {
    host_header {
      values = tolist(concat(split(",", each.value.host), [module.beanstalk_app_b[0].environment_cname]))
    }
  }
}
