## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates/tree/main/AutoScaling)
- But the demo's AMIs are extremely old, which cause the failure of EC2 instances cfn-init program. In this demo, we use a amazon Linux 2 AMI, and this newer version works well. 
- At the same time,  launch configurations deprecated problem is fixed in the demo. And launch template is used to replace the launch configurations.

```
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
cd aws-iac-lab/CloudFormation_Codes/
ll AutoScalingScheduledAction.yaml
```


NOTES:
As of **January 1, 2023**, new instance types are no longer supported in launch configurations.
Migrating your Auto Scaling groups to launch templates is needed. [Issue Resolved](https://github.com/aws-cloudformation/aws-cloudformation-templates/pull/481)

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-autoscaling-launchconfiguration.html
Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. For more information, see Launch configurations in the Amazon EC2 Auto Scaling User Guide.

## Description

AWS CloudFormation Sample Template AutoScalingScheduledAction: Create a load balanced, Auto Scaled sample website. This example creates an Auto Scaling group with time-based scheduled actions behind a load balancer with a simple health check. 
**WARNING** This template creates one or more Amazon EC2 instances and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.

## Resource

```
LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Metadata:
    ...
    
    Properties:
      LaunchTemplateData:
        KeyName: !Ref KeyName
        ImageId: ami-02f624c08a83ca16f
        SecurityGroups:
          - !Ref InstanceSecurityGroup
        InstanceType: !Ref InstanceType
        UserData: !Base64
          Fn::Sub: |
            #!/bin/bash
            yum update -y aws-cfn-bootstrap
            /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource LaunchTemplate --region ${AWS::Region}
            /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource WebServerGroup --region ${AWS::Region}
```

There are 3 parts have been changed compared with the original code:
1. LaunchTemplate is used to replace LaunchConfig
2. In `UserData`, `Fn::Sub` is used to replace `Fn::Join`. Because the latter one is more straight forward.
3. New version Amazon Linux 2 AMI is used.

## Validate

Visit output URL:
```
http://demo-45-elasticloa-av3mezfcxgt5-***********.us-east-1.elb.amazonaws.com/
```