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
