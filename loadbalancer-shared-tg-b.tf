##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
# Module to manage the association of the DNS record with the shared load balancer

data "aws_lb_listener" "shared_lb_listener_b" {
  for_each          = local.sh_rule_mappings_b
  load_balancer_arn = data.aws_lb.shared_lb[0].arn
  port              = local.sh_port_mappings_b[each.value.process].from_port
}

resource "aws_lb_target_group" "shared_lb_tg_b" {
  for_each = local.sh_rule_mappings_b
  name     = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
  port     = local.sh_port_mappings_b[each.value.process].to_port
  protocol = local.sh_port_mappings_b[each.value.process].protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    protocol            = local.sh_port_mappings_b[each.value.process].backend_protocol
    matcher             = "200-302"
  }

  tags = {
    Name        = "${var.load_balancer_shared_prefixes}-${each.key}-tg"
    Environment = "${var.release_name_b}-${var.namespace}-shared"
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

  tags = {
    Name               = "${var.load_balancer_shared_prefixes}-${each.key}-listener-rule"
    Environment        = "${var.release_name_b}-${var.namespace}-shared"
    Deployment_Traffic = var.deployment_traffic
  }
}
