# environment-template-bluegreen-awseb
Environment Template for AWS ElasticBeanstalk based apps with Blue-Green strategy deployment

## Table of Contents
1. [Procedure Flow](#procedure-flow)
2. [How-To](#how-to)
   1. [Promotion](#promotion)
   2. [Branch Creation for Configuration changes](#branch-creation-for-configuration-changes)
3. [Initial Setup](#initial-setup)
   1. [Configuring Backend](#configuring-backend)
   2. [Environment Variables for deployment automation](#environment-variables-for-deployment-automation)
   3. [Create OWNERS file](#create-owners-file)
4. [Pull Request 2nd Day](#pull-request-2nd-day)
   1. [Configuration Changes](#configuration-changes)

## Procedure Flow:
```
/promote (from app repos) --> /green-to-prod --> /approved
                  ^                            |
                  |                            |
                  `-------- /rollback <--------'
```

## How-To
### Promotion:
Promotion process starts with creating an issue on APP Repository and issue the following comment:
```
/promote version=<version number> env=<this environment suffix> {tracking_d=CUSTOM TRACKING ID}
```
Version suffix stands for the name after `environment-<organization>-` on this repository name.

### Branch Creation for Configuration changes
This will create a new Branch with following naming:
* config-< declarative branch name >
*  Run Following command on the new branch
  ```shell
  make config
  ```
* Do all configuration changes on **./values/**
* Run update on each configuration change
  ```shell
  make update
  ```
* Commit changes to the branch and push to repository
* Create a new pull request in order to start the deployment in blue/green way.

## Initial Setup
### Configuring Backend
First step is to configure the backend configuration for the environment
this is done copying the following file: `backend.tf_template` as `backend.tf`
there is a asample configuration for S3 backend where it can be done but
you can select whatever backend suits for the case. <br/>
Documentation about Terraform Backends can be found **[here](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)**.

### Environment Variables for deployment automation
The second point is to configure the environment variables to
setup this environment and maintain the S3 Bucket and deployment pipeline. <br/>

First step is to run the following command:
```shell
make init
```

### Create OWNERS file
This file is require to configure the automation workflow
you have to copy current `OWNERS_template` to `OWNERS
* For this kind of repository you must have the following set:
  ```yaml
  automatic: false
  ```
* Branch protection is set as default for this kind of repository:
  ```yaml
  branchProtection: true
  ```
  Branch will be protected automatically in order to preserve consistency on master branch.
* Protected sources are set as default but can be expanded:
  ```yaml
  protectedSources:
  - "*.tf"
  - "*.tfvars"
  - OWNERS
  - Makefile
  - .github
  ```
  Any changes on these files will fail the checks and invalidate the merge of the pull request.
* Adjust the number of required reviewers, remember that the approvals
  should fulfill the number selected here, the entry is required.
  ```yaml
  requiredReviewers: 2
  ```
* Next you have to configure the valid reviewers/approvers on the workflow
  the entry is required, the users listed are the GitHub Ids.
  ```yaml
  reviewers:
    - user1
    - user2
    - user3
  ```
* Push changes to Master ...
* Proceed with Promotion Process.

### (TBD) More documentation to be added soon.

## Pull Request 2nd Day
On each values changes, push into the branch and create a pull request against master branch.~~~~

### Configuration changes
* Do all configuration changes on **./values/**
* Commit changes to the branch and push to repository
