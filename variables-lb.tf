##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "load_balancer_public" {
  type        = bool
  default     = false
  description = "(optional) Setting to make Application Load Balancer, defaults to public Load Balancer, Default: false"
}

variable "load_balancer_ssl_certificate_id" {
  type        = string
  description = "(required) SSL certificate ID in the same Region to attach to LB."
  default     = ""
  #  sensitive   = true
}

variable "load_balancer_ssl_policy" {
  type        = string
  default     = null
  description = "(optional) SSL policy to apply to LB, default: null, defaults to what AWS has as default."
}

variable "load_balancer_alias" {
  type        = string
  default     = ""
  description = "(optional) Required load balancer alias,"
}

variable "load_balancer_shared" {
  type        = bool
  default     = false
  description = "(optional) Setting to make Application Load Balancer, defaults to public Load Balancer, Default: false"
}

variable "load_balancer_shared_name" {
  type        = string
  default     = ""
  description = "(optional) Shared Load Balancer ARN id to use, Default: (empty)"
}