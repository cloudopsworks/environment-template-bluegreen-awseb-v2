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
NEW_BG_STATE :=

.PHONY: init
.PHONY: checkbluegreen
.PHONY: VERSION
.PHONY: version
.PHONY: module.tf
.PHONY: config
.PHONY: promote
.PHONY: green-to-prod
.PHONY: decomm-blue
.PHONY: update


module.tf:
	@if [ ! -d values/${TARGET} ] ; then \
		echo "Module values/${TARGET} not found... making placeholder." ; \
		mkdir -p values/${TARGET}/ ; \
		touch values/$(TARGET)/.placeholder ; \
	else echo "Module values/${TARGET} found... all OK" ; \
	fi

checkbluegreen:
	$(info "BlueGreen Check")
	@if [ ! -f .bluegreen_state ] ; then \
		echo "a" > .bluegreen_state ; \
		sed -i -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars ; \
		sed -i -e "s/deployment_a_deactivated[ \t]*=.*/deployment_a_deactivated = false/g" terraform.tfvars ; \
	fi

.PHONY: state
state:
	$(info "Checking state")
#ifneq ("$(wildcard .bluegreen_state)","")
	$(eval BLUEGREEN_STATE = $(shell head -n 1 .bluegreen_state |head -c 1))
#endif

version: VERSION checkbluegreen state module.tf
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
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(BLUEGREEN_STATE)

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
	sed -i "" -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/default_bucket_prefix[ \t]*=.*/default_bucket_prefix = \"$(CURR)\"/" terraform.tfvars
	sed -i -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	@if [ ! -f backend.tf ] ; then \
		echo "Backend backend.tf not found... copying from template" ; \
		cp backend.tf_template backend.tf ; \
	else echo "Backend terraform.tfvars found... all OK" ; \
	fi
	@if [ ! -f OWNERS ] ; then \
		echo "Owners file OWNERS not found... copying from template" ; \
		cp OWNERS_template OWNERS ; \
	else echo "Owners file OWNERS found... all OK" ; \
	fi

.PHONY: bgstate
bgstate:
ifeq ($(shell head -n 1 .bluegreen_state |head -c 1),a)
override NEW_BG_STATE := b
else
override NEW_BG_STATE := a
endif

config: checkbluegreen state bgstate
	@read -p "Enter Branch Name (no spaces):" the_branch ; \
	git checkout -b config-$${the_branch} ; \
	git push -u origin config-$${the_branch}
ifeq ($(OS),Darwin)
	sed -i "" -e "s/deployment_$(NEW_BG_STATE)_deactivated[ \t]*=.*/deployment_$(NEW_BG_STATE)_deactivated = false/g" terraform.tfvars
	ver=$$(grep "app_version_$(BLUEGREEN_STATE)" terraform.tfvars | cut -d '=' -f 2- | tr -d ' "') ; \
	sed -i "" -e "s/app_version_$(NEW_BG_STATE)[ \t]*=.*/app_version_$(NEW_BG_STATE) = \"$${ver}\"/g" terraform.tfvars
else ifeq ($(OS),Linux)
	sed -i -e "s/deployment_$(NEW_BG_STATE)_deactivated[ \t]*=.*/deployment_$(NEW_BG_STATE)_deactivated = false/g" terraform.tfvars
	ver=$$(grep "app_version_$(BLUEGREEN_STATE)" terraform.tfvars | cut -d '=' -f 2- | tr -d ' "') ; \
	sed -i -e "s/app_version_$(NEW_BG_STATE)[ \t]*=.*/app_version_$(NEW_BG_STATE) = \"$${ver}\"/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	echo "$(NEW_BG_STATE)" > .bluegreen_state
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(NEW_BG_STATE)


update: checkbluegreen state bgstate
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(BLUEGREEN_STATE)


promote:
ifeq ($(OS),Darwin)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	if [ "$$green_server_version" = "a" ] ; then \
	  green_server_version="b" ; \
	else \
	  green_server_version="a" ; \
	fi ; \
	sed -i "" -e "s/deployment_$${green_server_version}_deactivated[ \t]*=.*/deployment_$${green_server_version}_deactivated = false/g" terraform.tfvars ; \
	echo "$$green_server_version" > .bluegreen_state
else ifeq ($(OS),Linux)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	if [ "$$green_server_version" = "a" ] ; then \
	  green_server_version="b" ; \
	else \
	  green_server_version="a" ; \
	fi ; \
	sed -i -e "s/deployment_$${green_server_version}_deactivated[ \t]*=.*/deployment_$${green_server_version}_deactivated = false/g" terraform.tfvars ; \
	echo "$$green_server_version" > .bluegreen_state
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif


green-to-prod:
ifeq ($(OS),Darwin)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	sed -i "" -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"$${green_server_version}\"/g" terraform.tfvars
else ifeq ($(OS),Linux)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	sed -i -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"$${green_server_version}\"/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif


decomm-blue:
ifeq ($(OS),Darwin)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	blue_server_version=a ; \
	if [ $$green_server_version = $$blue_server_version ]; then \
	blue_server_version="b" ; \
	fi ; \
	sed -i "" -e "s/deployment_$${blue_server_version}_deactivated[ \t]*=.*/deployment_$${blue_server_version}_deactivated = true/g" terraform.tfvars
else ifeq ($(OS),Linux)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	blue_server_version=a ; \
	if [ $$green_server_version = $$blue_server_version ]; then \
	blue_server_version="b" ; \
	fi ; \
	sed -i -e "s/deployment_$${blue_server_version}_deactivated[ \t]*=.*/deployment_$${blue_server_version}_deactivated = true/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
