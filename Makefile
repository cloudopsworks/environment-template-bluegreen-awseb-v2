##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
TRONADOR_AUTO_INIT := true

-include $(shell curl -sSL -o .tronador "https://cowk.io/acc"; echo .tronador)

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

.PHONY: env/init
.PHONY: env/checkbluegreen
.PHONY: VERSION
.PHONY: env/version
.PHONY: module.tf
.PHONY: env/config
.PHONY: env/promote
.PHONY: green/to/prod
.PHONY: env/decomm/blue
.PHONY: env/update


module.tf:
	@if [ ! -d values/${TARGET} ] ; then \
		echo "Module values/${TARGET} not found... making placeholder." ; \
		mkdir -p values/${TARGET}/ ; \
		touch values/$(TARGET)/.placeholder ; \
		mkdir -p values/${TARGET}/.ebextensions ; \
		cp -p modules/extensions/ssh-limit.config packages/${TARGET}/.ebextensions/ ; \
	else echo "Module values/${TARGET} found... all OK" ; \
	fi

env/checkbluegreen:
	$(info "BlueGreen Check")
ifeq ($(OS),darwin)
	@if [ ! -f .bluegreen_state ] ; then \
		echo "a" > .bluegreen_state ; \
		sed -i "" -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars ; \
		sed -i "" -e "s/deployment_a_deactivated[ \t]*=.*/deployment_a_deactivated = false/g" terraform.tfvars ; \
	fi
else ifeq ($(OS),linux)
	@if [ ! -f .bluegreen_state ] ; then \
		echo "a" > .bluegreen_state ; \
		sed -i -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars ; \
		sed -i -e "s/deployment_a_deactivated[ \t]*=.*/deployment_a_deactivated = false/g" terraform.tfvars ; \
	fi
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif

.PHONY: env/state
env/state:
	$(info "Checking state")
#ifneq ("$(wildcard .bluegreen_state)","")
	$(eval BLUEGREEN_STATE = $(shell head -n 1 .bluegreen_state |head -c 1))
#endif

SOL_STACK := $(shell grep -E "^solution_stack\s*=" terraform.tfvars | awk -F\" '{print $$2}')

env/version: VERSION env/checkbluegreen env/state module.tf
ifeq ($(OS),darwin)
	sed -i "" -e "s/MODULE_NAME/$(TARGET)/g" terraform.tfvars
	sed -i "" -e "s/source_name_$(BLUEGREEN_STATE)[ \t]*=.*/source_name_$(BLUEGREEN_STATE) = \"$(CHART)\"/" terraform.tfvars
	sed -i "" -e "s/release_name_$(BLUEGREEN_STATE)[ \t]*=.*/release_name_$(BLUEGREEN_STATE) = \"$(TARGET)\"/" terraform.tfvars
	sed -i "" -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = \"$(TARGET)\"/" terraform.tfvars
	sed -i "" -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$(TARGET)\-ingress\"/" terraform.tfvars
	sed -i "" -e "s/app_version_$(BLUEGREEN_STATE)[ \t]*=.*/app_version_$(BLUEGREEN_STATE) = \"$(RELEASE_VERSION)\"/g" terraform.tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i "" -e "s/solution_stack[ \t]*=.*/solution_stack = \"$(PLATFORM)\"/g" terraform.tfvars ; \
		sed -i "" -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(PLATFORM)\"/g" terraform.tfvars ; \
	else \
		sed -i "" -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(SOL_STACK)\"/g" terraform.tfvars ; \
	fi
	sed -i "" -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(SOL_STACK)\"/g" terraform.tfvars
	@if [[ "$(PACKAGE_NAME)" != "" && "$(PACKAGE_TYPE)" != "" ]] ; then \
		sed -i "" -e "s|gh_package_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_$(BLUEGREEN_STATE) = true|g" terraform.tfvars ; \
	else \
		sed -i "" -e "s|gh_package_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_$(BLUEGREEN_STATE) = false|g" terraform.tfvars ; \
	fi
	@if [ "$(PACKAGE_NAME)" != "" ] ; then \
		sed -i "" -e "s|gh_package_name_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_name_$(BLUEGREEN_STATE) = \"$(PACKAGE_NAME)\"|" terraform.tfvars ; \
	fi
	@if [ "$(PACKAGE_TYPE)" != "" ] ; then \
		sed -i "" -e "s|gh_package_type_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_type_$(BLUEGREEN_STATE) = \"$(PACKAGE_TYPE)\"|" terraform.tfvars ; \
	fi
else ifeq ($(OS),linux)
	sed -i -e "s/MODULE_NAME/$(TARGET)/g" terraform.tfvars
	sed -i -e "s/source_name_$(BLUEGREEN_STATE)[ \t]*=.*/source_name_$(BLUEGREEN_STATE) = \"$(CHART)\"/" terraform.tfvars
	sed -i -e "s/release_name_$(BLUEGREEN_STATE)[ \t]*=.*/release_name_$(BLUEGREEN_STATE) = \"$(TARGET)\"/" terraform.tfvars
	sed -i -e "s/load_balancer_log_prefix[ \t]*=.*/load_balancer_log_prefix = \"$(TARGET)\"/" terraform.tfvars
	sed -i -e "s/#load_balancer_alias[ \t]*=.*/#load_balancer_alias = \"$(TARGET)\-ingress\"/" terraform.tfvars
	sed -i -e "s/app_version_$(BLUEGREEN_STATE)[ \t]*=.*/app_version_$(BLUEGREEN_STATE) = \"$(RELEASE_VERSION)\"/g" terraform.tfvars
	@if [ "$(PLATFORM)" != "" ] ; then \
		sed -i -e "s/solution_stack[ \t]*=.*/solution_stack = \"$(PLATFORM)\"/g" terraform.tfvars ; \
		sed -i -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(PLATFORM)\"/g" terraform.tfvars ; \
	else \
		sed -i -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(SOL_STACK)\"/g" terraform.tfvars ; \
	fi
	@if [[ "$(PACKAGE_NAME)" != "" && "$(PACKAGE_TYPE)" != "" ]] ; then \
		sed -i -e "s|gh_package_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_$(BLUEGREEN_STATE) = true|g" terraform.tfvars ; \
	else \
		sed -i -e "s|gh_package_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_$(BLUEGREEN_STATE) = false|g" terraform.tfvars ; \
	fi
	@if [ "$(PACKAGE_NAME)" != "" ] ; then \
		sed -i -e "s|gh_package_name_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_name_$(BLUEGREEN_STATE) = \"$(PACKAGE_NAME)\"|g" terraform.tfvars ; \
	fi
	@if [ "$(PACKAGE_TYPE)" != "" ] ; then \
		sed -i -e "s|gh_package_type_$(BLUEGREEN_STATE)[ \t]*=.*|gh_package_type_$(BLUEGREEN_STATE) = \"$(PACKAGE_TYPE)\"|g" terraform.tfvars ; \
	fi
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(BLUEGREEN_STATE)

env/update-stack: env/checkbluegreen env/state module.tf
ifeq ($(OS),darwin)
	sed -i "" -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(SOL_STACK)\"/g" terraform.tfvars
else ifeq ($(OS),linux)
	sed -i -e "s/solution_stack_$(BLUEGREEN_STATE)[ \t]*=.*/solution_stack_$(BLUEGREEN_STATE) = \"$(SOL_STACK)\"/g" terraform.tfvars
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
override PACKAGE_NAME := $(shell cat VERSION | grep PACKAGE_NAME | cut -f 2 -d "=")
override PACKAGE_TYPE := $(shell cat VERSION | grep PACKAGE_TYPE | cut -f 2 -d "=")
else
	$(error Hey $@ File not found)
endif

env/clean:
	rm -f VERSION
	rm -f .destroy
	rm -f .beacon

env/init-template:
	@if [ ! -f terraform.tfvars ] ; then \
		echo "Initial Variables terraform.tfvars not found... copying from template" ; \
		cp terraform.tfvars_template terraform.tfvars ; \
	else echo "Initial Variables terraform.tfvars found... all OK" ; \
	fi

env/init: env/init-template
ifeq ($(OS),darwin)
	sed -i "" -e "s/default_bucket_prefix[ \t]*=.*/default_bucket_prefix = \"$(CURR)\"/" terraform.tfvars
	sed -i "" -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"a\"/g" terraform.tfvars
else ifeq ($(OS),linux)
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

.PHONY: env/bgstate
env/bgstate:
ifeq ($(shell head -n 1 .bluegreen_state |head -c 1),a)
override NEW_BG_STATE := b
else
override NEW_BG_STATE := a
endif

env/config: env/checkbluegreen env/state env/bgstate
	@read -p "Enter Branch Name (no spaces):" the_branch ; \
	git checkout -b config-$${the_branch} ; \
	git push -u origin config-$${the_branch}


env/update: env/checkbluegreen env/state env/bgstate
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(BLUEGREEN_STATE)


env/promote: env/checkbluegreen env/state env/bgstate
ifeq ($(OS),darwin)
	sed -i "" -e "s/deployment_$(NEW_BG_STATE)_deactivated[ \t]*=.*/deployment_$(NEW_BG_STATE)_deactivated = false/g" terraform.tfvars
	ver=$$(grep "app_version_$(BLUEGREEN_STATE)" terraform.tfvars | cut -d '=' -f 2- | tr -d ' "') ; \
	sed -i "" -e "s/app_version_$(NEW_BG_STATE)[ \t]*=.*/app_version_$(NEW_BG_STATE) = \"$${ver}\"/g" terraform.tfvars
else ifeq ($(OS),linux)
	sed -i -e "s/deployment_$(NEW_BG_STATE)_deactivated[ \t]*=.*/deployment_$(NEW_BG_STATE)_deactivated = false/g" terraform.tfvars
	ver=$$(grep "app_version_$(BLUEGREEN_STATE)" terraform.tfvars | cut -d '=' -f 2- | tr -d ' "') ; \
	sed -i -e "s/app_version_$(NEW_BG_STATE)[ \t]*=.*/app_version_$(NEW_BG_STATE) = \"$${ver}\"/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	echo "$(NEW_BG_STATE)" > .bluegreen_state
	find values/ -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum > .values_hash_$(NEW_BG_STATE)


green/to/prod:
ifeq ($(OS),darwin)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	sed -i "" -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"$${green_server_version}\"/g" terraform.tfvars
else ifeq ($(OS),linux)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	sed -i -e "s/deployment_traffic[ \t]*=.*/deployment_traffic = \"$${green_server_version}\"/g" terraform.tfvars
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif


env/decomm/blue:
ifeq ($(OS),darwin)
	green_server_version=$$(head -n 1 .bluegreen_state | head -c 1) ; \
	blue_server_version=a ; \
	if [ $$green_server_version = $$blue_server_version ]; then \
	blue_server_version="b" ; \
	fi ; \
	sed -i "" -e "s/deployment_$${blue_server_version}_deactivated[ \t]*=.*/deployment_$${blue_server_version}_deactivated = true/g" terraform.tfvars
else ifeq ($(OS),linux)
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

lint:
	$(SELF) terraform/install terraform/get-modules terraform/get-plugins terraform/lint terraform/validate
