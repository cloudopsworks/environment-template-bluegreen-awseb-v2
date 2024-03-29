##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "environment_name" {
  type        = string
  description = "(required) This configures the application environment-name"
}

variable "release_name_a" {
  type        = string
  description = "(required) This configures the application release-name"
}

variable "release_name_b" {
  type        = string
  description = "(required) This configures the application release-name"
}

variable "source_name_a" {
  type        = string
  description = "(required) this is the Helm CHART name sourced from organization repository."
}

variable "source_name_b" {
  type        = string
  description = "(required) this is the Helm CHART name sourced from organization repository."
}

variable "solution_stack" {
  type        = string
  description = <<EOF
(required) Solution stack is one of:
    java         = "^64bit Amazon Linux 2 (.*) running Corretto 8(.*)$"
    java11       = "^64bit Amazon Linux 2 (.*) running Corretto 11(.*)$"
    java17       = "^64bit Amazon Linux 2 (.*) running Corretto 17(.*)$"
    tomcatj8     = "^64bit Amazon Linux 2 (.*) Tomcat (.*) Corretto 8(.*)$"
    tomcatj11    = "^64bit Amazon Linux 2 (.*) Tomcat (.*) Corretto 11(.*)$"
    node         = "^64bit Amazon Linux 2 (.*) Node.js 12(.*)$"
    node14       = "^64bit Amazon Linux 2 (.*) Node.js 14(.*)$"
    node16       = "^64bit Amazon Linux 2 (.*) Node.js 16(.*)$"
    go           = "^64bit Amazon Linux 2 (.*) running Go (.*)$"
    docker       = "^64bit Amazon Linux 2 (.*) running Docker (.*)$"
    docker-m     = "^64bit Amazon Linux 2 (.*) Multi-container Docker (.*)$"
    net-core     = "^64bit Amazon Linux 2 (.*) running .NET Core(.*)$"
    python38     = "^64bit Amazon Linux 2 (.*) running Python 3.8(.*)$"
    python37     = "^64bit Amazon Linux 2 (.*) running Python 3.7(.*)$"
    net-core-w16 = "^64bit Windows Server Core 2016 (.*) running IIS (.*)$"
    net-iis-w12  = "^64bit Windows Server 2012 R2 (.*) running IIS (.*)$"
    net-core-w12 = "^64bit Windows Server Core 2012 R2 (.*) running IIS (.*)$"

Or explicity name the complete stack available from AWS, to prevent undesired stack upgrades.
EOF
}

variable "source_force_compressed" {
  type        = bool
  description = "(optional) Force to treat the source package to be compressed type. Default is false."
  default     = false
}

variable "source_compressed_type" {
  type        = string
  description = "(optional) The type of the source package. Default is null."
  default     = "zip"
}