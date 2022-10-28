##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
output "url_cname" {
  value = format("%s.%s", var.app_domain_alias, var.app_domain_name)
}

output "url_deployment_a" {
  value = count(module.beanstalk_app_a) > 0 ? module.beanstalk_app_a[0].environment_cname : ""
}

output "url_deployment_b" {
  value = count(module.beanstalk_app_b) > 0 ? module.beanstalk_app_b[0].environment_cname : ""
}