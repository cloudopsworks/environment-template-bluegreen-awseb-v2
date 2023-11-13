##
# (c) 2023 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "gh_package_a" {
  type        = bool
  description = "(optional) Set to true if the package of the 'a' instance should be downloaded from GitHub Packages."
  default     = false
}
variable "gh_package_b" {
  type        = bool
  description = "(optional) Set to true if the package of the 'b' instance should be downloaded from GitHub Packages."
  default     = false
}

variable "gh_package_name" {
  type        = string
  description = "(optional) The name of the package to download from GitHub Packages."
  default     = ""
}

variable "gh_package_type" {
  type        = string
  description = "(optional) The type of the package to download from GitHub Packages."
  default     = ""
}