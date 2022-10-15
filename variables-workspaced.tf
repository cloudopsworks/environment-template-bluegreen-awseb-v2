##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
variable "default_version" {
  type        = string
  description = "(Required) Version to be applied during the workspace election."
  default     = ""
}

variable "dns_weight" {
  type        = number
  description = "(Required) Weight to apply for DNS weighted distribution."
  default     = -1
}