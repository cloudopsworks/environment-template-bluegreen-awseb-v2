##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "cloudwatch_alarm_enabled" {
  type        = bool
  default     = false
  description = "(optional) Enable CloudWatch Alarms for each Environment. Default is false."
}

variable "cloudwatch_alarm_destination" {
  type        = string
  default     = ""
  description = "(optional) ARN of the SNS Topic to send CloudWatch Alarms to. This must be entered if cloudwatch_alarms_enabled is true or the plan will fail."
}

variable "cloudwatch_alarm_threshold" {
  type        = number
  default     = 15
  description = "(optional) The threshold for the CloudWatch Alarm. Default is 15."
}