##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "beanstalk_application" {
  type        = string
  description = "(required) Beanstalk application name to deploy to."
}

variable "beanstalk_ec2_key" {
  type        = string
  description = "(optional) Existing EC2 Key for connecting via SSH. Default is null (connect may be possible through SSM)."
  default     = null
}

variable "beanstalk_ami_id" {
  type        = string
  description = "(optional) Existing AMI ID as to be model to launch Beanstalk Environment. Default is null."
  default     = null
}

variable "beanstalk_instance_port" {
  type        = number
  description = "(optional) Default Instance Port for the application instance listener, Default Port: 80"
  default     = 80
}

variable "beanstalk_enable_spot" {
  type        = bool
  description = "(optional) Flag to enable SPOT instance request for Beanstalk applications, for production loads SPOT instances should be checked thoroughly. Default: false"
  default     = false
}

variable "beanstalk_default_retention" {
  type        = number
  description = "(optional) Default Retention of objects on the deployed application. Default: 90 days."
  default     = 90
}

variable "beanstalk_instance_volume_size" {
  type        = number
  description = "(optional) Default instance volume size in GB. Default 10gb."
  default     = 10
}

variable "beanstalk_instance_volume_type" {
  type        = string
  description = "(optional) Default EC2 instance volume type. Default: gp2"
  default     = "gp2"
}

variable "beanstalk_instance_profile" {
  type        = string
  description = "(optional) EC2 instance profile to apply to All instances in app. Default: null."
  default     = null
}

variable "beanstalk_service_role" {
  type        = string
  description = "(optional) EC2 instance service role to apply to all instances in app. Default: null."
  default     = null
}

variable "beanstalk_min_instances" {
  type        = number
  description = "(optional) Minimum number of instances to run in the environment. Default: 1"
  default     = 1
}

variable "beanstalk_max_instances" {
  type        = number
  description = "(optional) Maximum number of instances to run in the environment. Default: 1"
  default     = 1
}

variable "beanstalk_port_mappings" {
  type        = list(any)
  default     = []
  description = <<EOF
Optional variable for mapping ports to backend ports:
port_mappings = [
  {
    name      = "default"
    from_port = 80
    to_port   = 8081
    protocol  = "HTTP"
  },
  {
    name             = "port443"
    from_port        = 443
    to_port          = 8443
    protocol         = "HTTPS"
    backend_protocol = "HTTPS"
  }
]
EOF
}

variable "extra_settings" {
  type        = list(any)
  default     = []
  description = "(optional) Extra ElasticBeanstalk Settings in AWS format."
}

variable "beanstalk_lb_sg" {
  type        = list(any)
  default     = []
  description = "(optional) List of Security Groups to apply to the Load Balancer."
}

variable "beanstalk_target_sg" {
  type        = list(any)
  default     = []
  description = "(optional) List of Security Groups to apply to the Target Group."
}

variable "beanstalk_scale_rule" {
  type = object({
    trigger         = string, #"network-out|network-in|cpu|latency|request-count|target-response-time|disk-w-ops|disk-r-ops|disk-w-bytes|disk-r-bytes"
    breach_duration = number,
    statistic       = string, #"avg|min|max|sum"
    unit            = string, #"sec|pct|bytes|bits|count|bytes-s|bits-s|count-s|none"
    up_threshold    = number,
    up_increment    = number,
    down_threshold  = number,
    down_increment  = number
  })
  default     = null
  description = <<EOF
(optional) Scale Rule to apply to the environment. Default: null.
Is an object defined by this structure:
{
  trigger        = "network-out|network-in|cpu|latency|request-count|target-response-time|disk-w-ops|disk-r-ops|disk-w-bytes|disk-r-bytes"
  statistic      = "avg|min|max|sum"
  unit           = "sec|pct|bytes|bits|count|bytes-s|bits-s|count-s|none"
  breach_duration = [number], defaults to 5
  up_threshold   = [number], defaults to 6000000
  up_increment   = [number], defaults to 1
  down_threshold = [number], defaults to 2000000
  down_increment = [number] defaults to -1
}
EOF

#  validation {
#    condition = var.beanstalk_scale_rule != null && (var.beanstalk_scale_rule.trigger && var.beanstalk_scale_rule.statistic != null && var.beanstalk_scale_rule.unit != null)
#    error_message = "beanstalk_scale_rule must be null or an object with the following structure: { trigger = string, statistic = string, unit = string, breach_duration = number, up_threshold = number, up_increment = number, down_threshold = number, down_increment = number }"
#  }
}