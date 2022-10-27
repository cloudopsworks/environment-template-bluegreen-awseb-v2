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
