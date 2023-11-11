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