##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "deployment_traffic" {
  type = string
  validation {
    condition     = var.deployment_traffic == "a" || var.deployment_traffic == "b"
    error_message = "Variable must indicate blue green deployment: 'a' or 'b'"
  }
  description = "(required) Indicator which deployment is enabled, this manages at update time where the traffic flows."
}

variable "app_version_a" {
  type        = string
  description = "(required) version of the application in SEMVER format, for Deployment A"
}

variable "app_version_b" {
  type        = string
  description = "(required) version of the application in SEMVER format, for Deployment B"
}

variable "solution_stack_a" {
  type        = string
  description = "(required) Solution Stack to apply to the deployment A, allows individual stacks for each deployment."
}

variable "solution_stack_b" {
  type        = string
  description = "(required) Solution Stack to apply to the deployment B, allows individual stacks for each deployment."
}
variable "deployment_a_deactivated" {
  type        = bool
  description = "(required) Deployment A deactivation flag, if true all resources in A deployment will be destroyed."
}

variable "deployment_b_deactivated" {
  type        = bool
  description = "(required) Deployment B deactivation flag, if true all resources in B deployment will be destroyed."
}