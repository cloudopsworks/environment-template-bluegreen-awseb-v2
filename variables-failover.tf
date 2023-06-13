##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "failover_enabled" {
  type        = bool
  default     = false
  description = "(optional) Enable Failover for the records created in this zone. Defaults to false."
}

variable "failover_domain_alias" {
  type        = string
  default     = ""
  description = "(optional) The domain name of the primary record. Required if failover_enabled is true."
}

variable "failover_type" {
  type        = string
  default     = "primary"
  description = "(optional) The type of failover. Must be either primary or secondary. Defaults to primary."
  validation {
    condition     = can(regex("^(primary|secondary)$", var.failover_type))
    error_message = "Failover type must be either primary or secondary."
  }
}