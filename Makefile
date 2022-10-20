##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
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
BLUEGREEN_STATE :=

.PHONY: VERSION
.PHONY: version
.PHONY: module.tf
.PHONY: checkbluegreen


module.tf:
	@if [ ! -d values/${TARGET} ] ; then \
		echo "Module values/${TARGET} not found... making placeholder." ; \
		mkdir -p values/${TARGET}/ ; \
		touch values/$(TARGET)/.placeholder ; \
	else echo "Module values/${TARGET} found... all OK" ; \
	fi

checkbluegreen:
	@if [ ! -f .bluegreen_state ] ; then \
		echo -n "a" > .bluegreen_state ; \
		sed -i -e "s/deployment_a_enabled[ \t]*=.*/deployment_a_enabled = true/g" terraform.tfvars ; \
		mv app-module-a.tf.deactivated app-module-a.tf \
	fi
override BLUEGREEN_STATE := $(shell head -n 1 .bluegreen_state |head -c 1)

version: VERSION checkbluegreen module.tf 
ifeq ($(OS),Darwin)
	sed -i "" -e "s/MODULE_NAME/$(TARGET)/g" terraform.tfvars
	sed -i "" -e "s/source_name[ \t]*=.*/source_name = \"$(CHART)\"/" terraform.tfvars
	sed -i "" -e "s/release_name[ \t]*=.*/release_name = \"$(TARGET)\"/" terraform.tfvars
	sed -i "" -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = \"$(TARGET)\"/" terraform.tfvars
	sed -i "" -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$(TARGET)\-ingress\"/" terraform.tfvars
	sed -i "" -e "s/app_version_$(BLUEGREEN_STATE)[ \t]*=.*/app_version_$(BLUEGREEN_STATE) = \"$(RELEASE_VERSION)\"/g" terraform.tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i "" -e "s/SOLUTION_STACK/$(PLATFORM)/g" terraform.tfvars ; \
	fi 
else ifeq ($(OS),Linux)
	sed -i -e "s/MODULE_NAME/$(TARGET)/g" terraform.tfvars
	sed -i -e "s/source_name[ \t]*=.*/source_name = \"$(CHART)\"/" terraform.tfvars
	sed -i -e "s/release_name[ \t]*=.*/release_name = \"$(TARGET)\"/" terraform.tfvars
	sed -i -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = \"$(TARGET)\"/" terraform.tfvars
	sed -i -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$(TARGET)\-ingress\"/" terraform.tfvars
	sed -i -e "s/app_version_$(BLUEGREEN_STATE)[ \t]*=.*/app_version_$(BLUEGREEN_STATE) = \"$(RELEASE_VERSION)\"/g" terraform.tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i -e "s/SOLUTION_STACK/$(PLATFORM)/g" terraform.tfvars ; \
	fi
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
