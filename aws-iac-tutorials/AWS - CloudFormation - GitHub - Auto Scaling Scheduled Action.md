## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates/tree/main/AutoScaling). There are 2 problems that need to be fixed as follows:
- Launch configurations has been deprecated by amazon official. And launch template should be used to replace the deprecated launch configurations.
- AWS CloudFormation function `!Join` and `!Sub` are different. When using the `!Join` method, you need to explicitly include a newline character to indicate line breaks.

GitHub PR:
https://github.com/aws-cloudformation/aws-cloudformation-templates/pull/482

## Obtain the source code

```
git clone https://github.com/pikachuSparkle/aws-cloudformation-templates.git
cd aws-cloudformation-templates/AutoScaling/
ll AutoScalingScheduledAction.yaml
```

OR

```
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
cd aws-iac-lab/CloudFormation_Codes
ll AutoScalingScheduledAction.yaml
```

## References

As of **January 1, 2023**, new instance types are no longer supported in launch configurations.
Migrating your Auto Scaling groups to launch templates is needed. [Issue Resolved](https://github.com/aws-cloudformation/aws-cloudformation-templates/pull/481)

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-autoscaling-launchconfiguration.html
Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. The AWS official strongly recommend that you do not use launch configurations. For more information, see Launch configurations in the Amazon EC2 Auto Scaling User Guide.

## Description

AWS CloudFormation Sample Template AutoScalingScheduledAction: Create a load balanced, Auto Scaled sample website. This example creates an Auto Scaling group with time-based scheduled actions behind a load balancer with a simple health check. 
**WARNING** This template creates one or more Amazon EC2 instances and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.

## Resource

```
WebServerGroup:
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MinInstancesInService: 1
        MaxBatchSize: 1
        PauseTime: PT15M
        WaitOnResourceSignals: true
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AvailabilityZones: !GetAZs
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: 2
      MaxSize: 5
      LoadBalancerNames:
        - !Ref ElasticLoadBalancer
```

```
LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Metadata:
      Comment: Install a simple application
      AWS::CloudFormation::Init:
        config:
          packages:
            yum:
              httpd: []
          files:
            /var/www/html/index.html:
            ...
            /etc/cfn/cfn-hup.conf:
              content: !Sub |
                [main]
                stack=${AWS::StackId}
                region=${AWS::Region}
              mode: "000400"
              owner: root
              group: root
            /etc/cfn/hooks.d/cfn-auto-reloader.conf:
              content: !Sub |
                [cfn-auto-reloader-hook]
                triggers=post.update
                path=Resources.LaunchTemplate.Metadata.AWS::CloudFormation::Init
                action=/opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource LaunchTemplate --region ${AWS::Region}
                runas=root
    
    Properties:
      LaunchTemplateData:
        KeyName: !Ref KeyName
        ImageId: 
        ...
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

There are 2 problems have been fixed compared with the original code:
1. LaunchTemplate is used to replace LaunchConfig
2. Replace `Fn::Join` with `Fn::Sub` and replace `!Join` with `!Sub`. When using the `!Join` method, you need to explicitly include a newline character to indicate line breaks.  The latter one is more straight forward. 

## Validate

Visit output URL:
```
http://demo-45-elasticloa-av3mezfcxgt5-***********.us-east-1.elb.amazonaws.com/
```

## NOTES
The demo's AMIs are extremely outdated. In this demo, you can use a Amazon Linux 2 AMI `ami-02f624c08a83ca16f`, and this newer version works well and easy to debug.