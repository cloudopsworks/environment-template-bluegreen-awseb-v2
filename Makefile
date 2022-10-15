##
# (c) 2021 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
OS := $(shell uname)
PWD := $(shell pwd)
CURR := $(shell basename $(PWD))
VERFOUND := $(shell [ -f VERSION ] && echo 1 || echo 0)
RELEASE_VERSION :=
TARGET :=
CHART :=
PLATFORM :=
DESTROYFOUND := $(shell [ -f .destroy ] && echo 1 || echo 0)
DATE :=	$(shell date +%Y%m%d-%H%M%S.%s)


.PHONY: VERSION
.PHONY: version
.PHONY: module.tf
.PHONY: checktier
.PHONY: deployed-beacon
.PHONY: completed-beacon
.PHONY: switched-beacon
.PHONY: rollback-tier

module.tf:
	@if [ ! -f $(TARGET)-module.tf ] ; then \
		echo "Module $(TARGET)-module.tf not found... copying from template" ; \
		cp template-module.tf_template $(TARGET)-module.tf ; \
		mkdir -p values/${TARGET}/ ; \
		touch values/$(TARGET)/.placeholder ; \
	else echo "Module $(TARGET)-module.tf found... all OK" ; \
	fi
# ifeq "" "$(T)"
# 	$(info )
# ifeq ($(OS),Darwin)
# else ifeq ($(OS),Linux)
# else
# 	echo "platfrom $(OS) not supported to release from"
# 	exit -1
# endif
# else
# 	$(info )
# endif

checktier:
	@if [ ! -f .tier_enabled ] ; then \
		echo "blue" > .tier_enabled ; \
		cp template-tier.tfvars_template blue.tfvars ; \
		sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" blue.tfvars ; \
	fi

version: VERSION checktier module.tf 
ifeq ($(OS),Darwin)
	sed -i "" -e "s/MODULE_NAME/$(TARGET)/g" $(TARGET)-module.tf
	sed -i "" -e "s/source_name[ \t]*=.*/source_name = \"$(CHART)\"/" $(TARGET)-module.tf
	sed -i "" -e "s/release_name[ \t]*=.*/release_name = \"$(TARGET)\"/" $(TARGET)-module.tf
	sed -i "" -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = format(\"%s-%s\", \"$(TARGET)\", terraform.workspace)/" $(TARGET)-module.tf
	sed -i "" -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$$\{format(\"%s-%s\", \"$(TARGET)\", terraform.workspace)\}\-ingress\"/" $(TARGET)-module.tf
	sed -i "" -e "s/default_version[ \t]*=.*/default_version = \"$(RELEASE_VERSION)\"/g" $(shell cat .tier_enabled).tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i "" -e "s/SOLUTION_STACK/$(PLATFORM)/g" $(TARGET)-module.tf ; \
	fi 
else ifeq ($(OS),Linux)
	sed -i -e "s/MODULE_NAME/$(TARGET)/g" $(TARGET)-module.tf
	sed -i -e "s/source_name[ \t]*=.*/source_name = \"$(CHART)\"/" $(TARGET)-module.tf
	sed -i -e "s/release_name[ \t]*=.*/release_name = \"$(TARGET)\"/" $(TARGET)-module.tf
	sed -i -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = format(\"%s-%s\", \"$(TARGET)\", terraform.workspace)/" $(TARGET)-module.tf
	sed -i -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$$\{format(\"%s-%s\", \"$(TARGET)\", terraform.workspace)\}\-ingress\"/" $(TARGET)-module.tf
	sed -i -e "s/default_version[ \t]*=.*/default_version = \"$(RELEASE_VERSION)\"/g" $(shell cat .tier_enabled).tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i -e "s/SOLUTION_STACK/$(PLATFORM)/g" $(TARGET)-module.tf ; \
	fi
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

switch-from-green: deploy-beacon
	echo "blue" > .tier_enabled
	echo "green" > .destroy
	@if [ ! -f blue.tfvars ] ; then \
		cp template-tier.tfvars_template blue.tfvars ; \
	fi
ifeq ($(OS),Darwin)
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" blue.tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" blue.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

switch-from-blue: deploy-beacon
	echo "green" > .tier_enabled
	echo "blue" > .destroy
	@if [ ! -f green.tfvars ] ; then \
		cp template-tier.tfvars_template green.tfvars ; \
	fi
ifeq ($(OS),Darwin)
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" green.tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" green.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

deploy-beacon:
	echo "deploy" > .beacon
	echo "$(DATE)" >> .beacon

closeoldtraffic-beacon:
	echo "close_old" > .beacon
	echo "$(DATE)" >> .beacon

opentraffic-beacon:
	echo "open_new" > .beacon
	echo "$(DATE)" >> .beacon

rollback-beacon:
	echo "rollback" > .beacon
	echo "$(DATE)" >> .beacon

close-old-traffic: closeoldtraffic-beacon 
ifeq ($(OS),Darwin)
	@if [ -f .destroy ] ; then \
		sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .destroy).tfvars ; \
	fi
else ifeq ($(OS),Linux)
	@if [ -f .destroy ] ; then \
		sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .destroy).tfvars ; \
	fi
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

open-new-traffic: opentraffic-beacon
ifeq ($(OS),Darwin)
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .tier_enabled).tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .tier_enabled).tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

close-traffic: 
ifeq ($(OS),Darwin)
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .tier_enabled).tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .tier_enabled).tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

force-traffic: closeoldtraffic-beacon
ifeq ($(OS),Darwin)
	@if [ -f .destroy ] ; then \
		sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .destroy).tfvars ; \
	fi
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .tier_enabled).tfvars
else ifeq ($(OS),Linux)
	@if [ -f .destroy ] ; then \
		sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .destroy).tfvars ; \
	fi
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .tier_enabled).tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

rollback-tier:
ifeq ($(DESTROYFOUND),1)
ifeq ($(OS),Darwin)
		sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .destroy).tfvars
else ifeq ($(OS),Linux)
		sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 10/g" $(shell cat .destroy).tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
endif

rollback: rollback-tier rollback-beacon
ifeq ($(OS),Darwin)
	sed -i "" -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .tier_enabled).tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/dns_weight[ \t]*=.*/dns_weight      = 0/g" $(shell cat .tier_enabled).tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif


VERSION:
ifeq ($(VERFOUND),1)
	$(info Version File OK)
override RELEASE_VERSION := $(shell cat VERSION | grep VERSION | cut -f 2 -d "=")
override TARGET := $(shell cat VERSION | grep TARGET | cut -f 2 -d "=")
override CHART := $(shell cat VERSION | grep CHART | cut -f 2 -d "=")
override PLATFORM := $(shell cat VERSION | grep PLATFORM | cut -f 2 -d "=")
else
	$(error Hey $@ File not found)
endif

clean:
	rm -f VERSION
	rm -f .destroy
	rm -f .beacon

init-template:
	@if [ ! -f terraform.tfvars ] ; then \
		echo "Initial Variables terraform.tfvars not found... copying from template" ; \
		cp terraform.tfvars_template terraform.tfvars ; \
	else echo "Initial Variables terraform.tfvars found... all OK" ; \
	fi

init: init-template
ifeq ($(OS),Darwin)
	sed -i "" -e "s/default_bucket_prefix[ \t]*=.*/default_bucket_prefix = \"$(CURR)\"/" terraform.tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/default_bucket_prefix[ \t]*=.*/default_bucket_prefix = \"$(CURR)\"/" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
