## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates)

There are two methods that you could obtain the demo codes:
1. From the AWS templates GitHub: [InstanceWithCfnInit.yaml](https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/EC2/InstanceWithCfnInit.yaml "InstanceWithCfnInit.yaml")
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/EC2/
ll ./InstanceWithCfnInit.yaml
```
2. From this repo
```
./CloudFormation_Codes/InstanceWithCfnInit.yaml
```

>NOTES:
>In AWS GitHub codes, there is a vital bug which has been fixed in this blog (fix committed).

```yaml
UserData: !Base64
        Fn::Sub: |-
          #!/bin/bash
          /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource Instance --region ${AWS::Region}
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource Instance --region ${AWS::Region}
```


## Code Analysis

This AWS CloudFormation template is designed to create an Amazon EC2 instance while utilizing `cfn-init` and `cfn-signal` for configuration management and resource signaling. Below is a detailed breakdown of the code, explaining its components and the underlying logic.

#### EC2 Instance Definition
```
Resources:
  Instance:
    CreationPolicy:
      ResourceSignal:
        Timeout: PT5M
```
- **Resources**: This section defines all AWS resources that will be created.
- **Instance**: The logical name of the EC2 instance being created.
- **CreationPolicy**: Specifies that CloudFormation should wait for a signal from the instance before it considers the creation complete. The timeout is set to 5 minutes (PT5M), meaning if no signal is received in this time, the creation will fail.

#### Instance Properties
```
    Type: AWS::EC2::Instance
    Metadata:
      guard:
        SuppressedRules:
          - EC2_INSTANCES_IN_VPC

```
- **Type**: Indicates that this resource is an EC2 instance.
- **Metadata**: Contains additional configuration details. Here, it suppresses a rule that would require instances to be launched within a VPC.

#### Configuration Management
```
      AWS::CloudFormation::Init:
        config:
          packages:
            yum:
              httpd: []

```
- **AWS::CloudFormation::Init**: This section allows for configuration of the instance after launch.
- **config**: Defines what configurations will be applied.
- **packages**: Specifies that the Apache HTTP server (`httpd`) should be installed using `yum`.

#### File Creation
```
          files:
            /var/www/html/index.html:
              content: |
                <body>
                  <h1>Congratulations, you have successfully launched the AWS CloudFormation sample.</h1>
                </body>
              mode: "000644"
              owner: root
              group: root

```

- **files**: Defines files to be created on the instance.
- An HTML file at `/var/www/html/index.html` is created with a success message. The file permissions are set to allow read access for everyone and write access only for the owner (root).

#### Configuration Files for cfn-hup
```
            /etc/cfn/cfn-hup.conf:
              content: !Sub |
                [main]
                stack=${AWS::StackId}
                region=${AWS::Region}
              mode: "000400"
              owner: root
              group: root

```
- This file configures `cfn-hup`, which monitors changes in CloudFormation stack metadata. It includes placeholders for stack ID and region, which are replaced with actual values during stack creation.

```
            /etc/cfn/hooks.d/cfn-auto-reloader.conf:
              content: !Sub |-
                [cfn-auto-reloader-hook]
                triggers=post.update
                path=Resources.LaunchConfig.Metadata.AWS::CloudFormation::Init
                action=/opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource Instance --region ${AWS::Region}
                runas=root

```
- Another configuration file for `cfn-hup`, which triggers `cfn-init` to re-run if updates are made to the metadata associated with the instance.

#### Service Management
```
          services:
            sysvinit:
              httpd:
                enabled: true
                ensureRunning: true
              cfn-hup:
                enabled: true
                ensureRunning: true
                files:
                  - /etc/cfn/cfn-hup.conf
                  - /etc/cfn/hooks.d/cfn-auto-reloader.conf

```

- **services**: Manages services on the instance.
- Both Apache (`httpd`) and `cfn-hup` are enabled and ensured to be running.

#### Instance Properties Continued
```
    Properties:
      ImageId: '{{resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64}}'
      InstanceType: t4g.nano
      KeyName: sample
      BlockDeviceMappings:
        - DeviceName: /dev/sda1
          Ebs:
            VolumeSize: 32

```
- **ImageId**: Retrieves the latest Amazon Linux AMI ID from AWS Systems Manager Parameter Store.
- **InstanceType**: Specifies the instance type as `t4g.nano`, suitable for lightweight workloads.
- **KeyName**: Refers to an existing key pair for SSH access to the instance.
- **BlockDeviceMappings**: Configures storage, specifying a 32 GB EBS volume attached as `/dev/sda1`.

#### User Data Script
```
      UserData: !Base64
        Fn::Sub: |-
          #!/bin/bash
          /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource Instance --region ${AWS::Region}
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource Instance --region ${AWS::Region}

```
- **UserData**: A script executed upon instance launch, encoded in base64.
    - It runs `cfn-init` to apply configurations defined in `AWS::CloudFormation::Init`.
    - After execution, it sends a signal back to CloudFormation using `cfn-signal`, indicating whether initialization was successful (exit status `$?`).

This CloudFormation template automates the creation and configuration of an EC2 instance, ensuring that necessary software is installed and configured correctly. By using `cfn-init` and `cfn-signal`, it provides a robust mechanism for managing infrastructure as code, enabling easy updates and monitoring of resource states within AWS.

## Deploy and Validate

- deploy the template with AWS dashboard console
- visit `http://ip` and shows `Congratulations, you have successfully launched the AWS CloudFormation sample.`

