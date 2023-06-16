##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  tags = merge(var.extra_tags, {
    Environment = format("%s-%s", var.release_name, var.namespace)
    Namespace   = var.namespace
    Release     = var.release_name
  })
}

data "aws_sns_topic" "topic_destination" {
  name = var.cloudwatch_alarm_destination
}

resource "aws_cloudwatch_metric_alarm" "metric_alarm_a" {
  count = !var.deployment_a_deactivated && var.cloudwatch_alarm_enabled ? 1 : 0

  alarm_name          = format("MetricsAlarm-%s-%s-%s-%s", var.region, var.release_name, var.namespace, "a")
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Maximum"
  threshold           = var.cloudwatch_alarm_threshold
  period              = 120
  evaluation_periods  = 2
  namespace           = "AWS/ElasticBeanstalk"
  metric_name         = "EnvironmentHealth"
  alarm_description   = "Metric Alarm for Beanstalk Application - Deployment A"
  actions_enabled     = true
  alarm_actions = [
    data.aws_sns_topic.topic_destination.arn
  ]
  dimensions = {
    EnvironmentName = module.beanstalk_app_a[0].environment_name
  }
  tags = local.tags
}


resource "aws_cloudwatch_metric_alarm" "metric_alarm_b" {
  count = !var.deployment_b_deactivated && var.cloudwatch_alarm_enabled ? 1 : 0

  alarm_name          = format("MetricsAlarm-%s-%s-%s", var.release_name, var.namespace, "b")
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Maximum"
  threshold           = var.cloudwatch_alarm_threshold
  period              = 120
  evaluation_periods  = 2
  namespace           = "AWS/ElasticBeanstalk"
  metric_name         = "EnvironmentHealth"
  alarm_description   = "Metric Alarm for Beanstalk Application - Deployment B"
  actions_enabled     = true
  alarm_actions = [
    data.aws_sns_topic.topic_destination.arn
  ]
  dimensions = {
    EnvironmentName = module.beanstalk_app_b[0].environment_name
  }
  tags = local.tags
}