# environment-template-bluegreen-awseb
Environment Template for AWS ElasticBeanstalk based apps with Blue-Green strategy deployment

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
/promote version=<version number> env=<this environment suffix>
```
Version suffix stands for the name after `environment-<organization>-` on this repository name.

### Configuration change
Create a new Branch with following naming:
* config-< declarative branch name >
Run Following command on the new branch
```
make config
```
Do all configuration changes on **./values/** <br/>
Commit changes to the branch and push to repository

### Initial Setup
#### Configuring Backend
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