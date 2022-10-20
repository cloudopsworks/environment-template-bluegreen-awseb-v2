##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "private_subnets" {
  type        = list(string)
  default     = []
  description = "(optional) Private subnets where the LB (if internal) and instances will reside."
}

variable "public_subnets" {
  type        = list(string)
  default     = []
  description = "(optional) Public subnets where the LB exposed to Internet will reside, this will be validated if *load_balancer_public=true*"
  #  validation {
  #    condition     = can((var.load_balancer_public && length(var.public_subnets) > 0) || !var.load_balancer_public)
  #    error_message = "Public subnets should be defined if LB is public."
  #  }
}

variable "vpc_id" {
  type        = string
  description = "(required) VPC ID where the instance will run."
}

variable "server_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "(optional) EC2 instance type list, first item will be used on on-demand instances."
}

variable "app_domain_name" {
  type        = string
  description = "(required) Domain Name that will be used to place the environment."
}

variable "app_domain_alias" {
  type        = string
  description = "(required) Domain alias that will be prepended to the domain name to resolve to de app."
}

variable "app_domain_disabled" {
  type = bool
  default = false
  description = "(optional) Flag to disable Domain Management for application."
}