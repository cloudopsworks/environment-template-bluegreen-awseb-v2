##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "deployment_enabled" {
  type        = string
  validation {
    condition = var.deployment_enabled == "a" || var.deployment_enabled == "b"
  }
  description = "(required) Indicator of Deployment A is enabled, resources will be alive if true, otherwise will be destroyed."
}

variable "app_version_a" {
  type        = string
  description = "(required) version of the application in SEMVER format, for Deployment A"
}

variable "app_version_b" {
  type        = string
  description = "(required) version of the application in SEMVER format, for Deployment B"
}
