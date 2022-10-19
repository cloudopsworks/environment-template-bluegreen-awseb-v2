##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "release_name" {
  type        = string
  description = "(required) This configures the application release-name"
}

variable "source_name" {
  type        = string
  description = "(required) this is the Helm CHART name sourced from organization repository."
}

variable "solution_stack" {
  type        = string
  description = <<EOF
(required) Solution stack is one of:
     java      = "^64bit Amazon Linux 2 (.*) Corretto 8(.*)$"
     java11    = "^64bit Amazon Linux 2 (.*) Corretto 11(.*)$"
     node      = "^64bit Amazon Linux 2 (.*) Node.js 12(.*)$"
     node14    = "^64bit Amazon Linux 2 (.*) Node.js 14(.*)$"
     go        = "^64bit Amazon Linux 2 (.*) Go (.*)$"
     docker    = "^64bit Amazon Linux 2 (.*) Docker (.*)$"
     docker-m  = "^64bit Amazon Linux 2 (.*) Multi-container Docker (.*)$"
     java-amz1 = "^64bit Amazon Linux (.*)$ running Java 8(.*)$"
     node-amz1 = "^64bit Amazon Linux (.*)$ running Node.js(.*)$"

Or explicity name the complete stack available from AWS, to prevent undesired stack upgrades.
EOF
}
