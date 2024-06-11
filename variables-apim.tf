##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "api_gw_enabled" {
  type        = bool
  description = "(optional) Enable APIM endpoint setup. Default is false."
  default     = false
}

variable "api_gw_vpc_link_name" {
  type        = string
  description = "(optional) Name of the VPC Link to be created. Default is empty."
  default     = ""
}

#api_gw_vpc_link_health = true # Enable this and below to change the type of healthcheck
variable "api_gw_vpc_link_health" {
  type    = bool
  default = false
}

#api_gw_vpc_link_protocol = "HTTPS"
variable "api_gw_vpc_link_protocol" {
  type    = string
  default = "HTTPS"
}

#api_gw_vpc_link_http_status = "200-401"
variable "api_gw_vpc_link_http_status" {
  type    = string
  default = "200-499"
}

#api_gw_vpc_link_path = "/"
variable "api_gw_vpc_link_path" {
  type    = string
  default = "/"
}
