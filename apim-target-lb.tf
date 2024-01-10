##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

## API GATEWAY LINK ENABLED only
# Will create all new link and NLB for the beanstalk environment.
# If you want to use an existing NLB, use the `vpc_link.use_existing = true` option
resource "aws_api_gateway_vpc_link" "apigw_rest_link" {
  count       = var.api_gw_enabled ? 1 : 0
  name        = var.api_gw_vpc_link_name == "" ? "api-gw-nlb-${lower(var.environment_name)}-${var.namespace}-nlb-link" : var.api_gw_vpc_link_name
  description = "VPC Link for API Gateway to NLB: api-gw-nlb-${lower(var.environment_name)}-${var.namespace}"
  target_arns = [aws_lb.apigw_rest_lb[0].arn]
  tags        = local.tags_global
}

#resource "aws_apigatewayv2_vpc_link" "apigw_http_link" {
#  for_each = local.apigw_nlb_configurations
#
#  name = "api-${lower(each.value.release.name)}-${var.namespace}-vpc-link"
#  subnet_ids = each.value.beanstalk.networking.private_subnets
#  security_group_ids = []
#  tags = local.tags[each.key]
#}

resource "aws_lb" "apigw_rest_lb" {
  count              = var.api_gw_enabled ? 1 : 0
  name               = "api-gw-nlb-${lower(var.environment_name)}-${var.namespace}"
  internal           = !var.load_balancer_public
  load_balancer_type = "network"
  subnets            = var.load_balancer_public ? var.public_subnets : var.private_subnets
  tags               = local.tags_global
}

resource "aws_lb_target_group" "apigw_rest_lb_tg" {
  count       = var.api_gw_enabled ? 1 : 0
  name        = "tg-${lower(var.environment_name)}-${var.namespace}-443"
  target_type = "alb"
  protocol    = "TCP"
  port        = 443
  vpc_id      = var.vpc_id
  tags        = local.tags_global

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "apigw_rest_lb_tg_att" {
  count            = var.api_gw_enabled ? 1 : 0
  target_group_arn = aws_lb_target_group.apigw_rest_lb_tg[0].arn
  target_id        = var.deployment_traffic == "a" ? module.beanstalk_app_a[0].load_balancer_id : module.beanstalk_app_b[0].load_balancer_id
}

resource "aws_lb_listener" "apigw_rest_lb_listener" {
  count             = var.api_gw_enabled ? 1 : 0
  load_balancer_arn = aws_lb.apigw_rest_lb[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apigw_rest_lb_tg[0].arn
  }
  tags = local.tags_global
}

## EXISTING NLB
# api_gateway:
#   vpc_link:
#     use_existing: true
#
#data "aws_lb" "apigw_rest_lb_link" {
#  for_each = local.apiqw_nlb_vpc_links
#
#  name = each.value.api_gateway.vpc_link.lb_name
#}
#
#resource "aws_lb_target_group" "apigw_rest_lb_tg_link" {
#  for_each = local.apiqw_nlb_vpc_links
#
#  name        = "tg-${lower(each.value.release.name)}-${var.namespace}-${each.value.api_gateway.vpc_link.listener_port}"
#  target_type = "alb"
#  protocol    = "TCP"
#  port        = try(each.value.api_gateway.vpc_link.to_port, each.value.api_gateway.vpc_link.listener_port)
#  vpc_id      = each.value.beanstalk.networking.vpc_id
#
#  health_check {
#    enabled  = true
#    protocol = try(each.value.api_gateway.vpc_link.health.protocol, "TCP")
#    matcher  = try(each.value.api_gateway.vpc_link.health.http_status, "")
#    path     = try(each.value.api_gateway.vpc_link.health.path, "")
#  }
#  tags = local.tags[each.key]
#}
#
#resource "aws_lb_target_group_attachment" "apigw_rest_lb_tg_att_link" {
#  for_each = local.apiqw_nlb_vpc_links
#
#  target_group_arn = aws_lb_target_group.apigw_rest_lb_tg_link[each.key].arn
#  target_id        = module.app[each.key].load_balancer_id
#}
#
#
#resource "aws_lb_listener" "apigw_rest_lb_listener_link" {
#  for_each = local.apiqw_nlb_vpc_links
#
#  load_balancer_arn = data.aws_lb.apigw_rest_lb_link[each.key].arn
#  port              = each.value.api_gateway.vpc_link.listener_port
#  protocol          = "TCP"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.apigw_rest_lb_tg_link[each.key].arn
#  }
#  tags = local.tags[each.key]
#
#  lifecycle {
#    replace_triggered_by = [aws_lb_target_group.apigw_rest_lb_tg_link[each.key]]
#  }
#}
