# environment-template-bluegreen-awseb
Environment Template for AWS ElasticBeanstalk based apps with Blue-Green strategy deployment

## Flow:
```
/promote (from app repos) --> /open-new --> /close-old --> /approved
                         |                                ^
                         |                                |
                         `--------> /force-switch --------'
```
