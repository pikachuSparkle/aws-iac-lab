This article follows the AWS CloudFormation Documentation [Deploy applications on Amazon EC2](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/deploying.applications.html)
We can use CloudFormation to automatically install, configure, and start applications on Amazon EC2 instances. Doing so enables you to easily duplicate deployments and update existing installations without connecting directly to the instance, which can save much time and effort.

CloudFormation includes a set of helper scripts (`cfn-init`, `cfn-signal`, `cfn-get-metadata`, and `cfn-hup`) that are based on `cloud-init`. You call these helper scripts from your CloudFormation templates to install, configure, and update applications on Amazon EC2 instances that are in the same template.

The following walkthrough describes how to create a template that launches a LAMP stack by using helper scripts to install, configure, and start Apache, MySQL, and PHP. You'll start with a simple template that sets up a basic Amazon EC2 instance running Amazon Linux, and then continue adding to the template until it describes a full LAMP stack.


## 1. Basic Amazon EC2 instance

Basically, a template is created for the CloudFormation stack.

This walkthrough start with a basic template that defines:
- a single Amazon EC2 instance 
- a security group that allows SSH traffic on port 22 and HTTP traffic on port 80,

The parameters section, in addition to the Amazon EC2 instance and security group, the template create three input parameters that: 
- specify the instance type
- an Amazon EC2 key pair to use for SSH access 
- an IP address range that can be used to SSH to the instance. 

The mapping section ensures that CloudFormation uses the correct AMI ID for the stack's region and the Amazon EC2 instance type. 

Finally, the output section outputs the public URL of the web server.

#### 1.1 Resources

The template defines two main resources:
1. **WebServerInstance**:
    - **Type**: AWS::EC2::Instance.
    - **Properties**:
        - Uses `FindInMap` functions to select the correct AMI based on region and instance type.
        - Specifies the instance type and associates it with a security group.
2. **WebServerSecurityGroup**:
    - **Type**: AWS::EC2::SecurityGroup.
    - **Properties**:
        - Allows HTTP access on port 80 and SSH access on port 22 from specified IP ranges.
#### 1.2 Parameters

The template includes parameters that allow users to customize the stack during creation:

1. **KeyName**:
    - **Description**: The name of an existing EC2 KeyPair for SSH access to the instance.
    - **Type**: AWS::EC2::KeyPair::KeyName.
    - **Constraint Description**: Must contain only ASCII characters.
2. **InstanceType**:
    - **Description**: Specifies the type of EC2 instance to be used for the web server.
    - **Type**: String with a default value of `t2.small`.
    - **Allowed Values**: A list of valid EC2 instance types ranging from `t1.micro` to various `m4` and `c4` types.
3. **SSHLocation**:
    - **Description**: The IP address range allowed for SSH access to the EC2 instance.
    - **Type**: String with constraints on length and format (CIDR notation).

#### 1.3 Mappings

Mappings define relationships between values, such as instance types and their corresponding architectures or AMIs (Amazon Machine Images):
- **AWSInstanceType2Arch**: Maps various instance types to their architecture (e.g., HVM64).
- **AWSRegionArch2AMI**: Maps AWS regions to specific AMIs based on architecture type.

#### 1.4 Outputs

The output section provides useful information after stack creation:
- **WebsiteURL**:
    - **Description**: URL for accessing the newly created LAMP stack.
    - **Value**: Constructs a URL using the public DNS name of the EC2 instance.

## 2. Deployment the template

To deploy the provided CloudFormation template using the AWS Management Console, follow these steps:
1. **Log in to the AWS Management Console**:
    - Go to the AWS website and sign in with your account credentials.
2. **Navigate to CloudFormation**:
    - In the search bar at the top of the console, type "CloudFormation" and select it from the dropdown menu.
3. **Create a New Stack**:
    - On the CloudFormation dashboard, click on the **"Create stack"** button.
    - Choose **"With new resources (standard)"**.
4. **Specify Template**:
    - You will be prompted to specify a template. You have two options here:
        - **Upload a template file**: Select this option if you have saved your template as a file on your computer. Click on **"Choose file"**, locate your template file, and select it.
        - **Amazon S3 URL**: If your template is stored in an S3 bucket, you can provide the URL to that template.
5. **Specify Stack Details**:
    - Enter a unique name for your stack in the **Stack name** field.
    - Fill in any parameters required by your template, such as `KeyName`, `InstanceType`, and `SSHLocation`. Make sure to provide valid values as per the constraints defined in your template.
6. **Configure Stack Options (Optional)**:
    - You can add tags to help identify your stack later, and configure additional options if needed. 
    - This step is optional. For example: `Name:DemoEC2`
7. **Review Your Settings**:
    - Review all the details you have entered. Ensure that everything is correct, especially the parameters and options.
8. **Create Stack**:
    - Click on the **"Create stack"** button to initiate the deployment of your CloudFormation stack.
    - This will cost 2 minutes
9. **Monitor Stack Creation**:
    - You can monitor the progress of your stack creation in the CloudFormation console under the **Stacks** section. 
    - The status will change from "CREATE_IN_PROGRESS" to "CREATE_COMPLETE" once finished.
10. **Access Your Deployed Resources**:
    - Once the stack creation is complete, you can find outputs such as the website URL in the Outputs tab of your stack details.

## 3. Template source code

You can get the source code from
```
./CloudFormation_Codes/Deploy_applications_on_Amazon_EC2_1.yaml
```

NOTES:
- The us-east-1 AZ has been tested and an ubuntu ec2 instances will been created
- Specify the name of an existing EC2 KeyPair in the same region where you're launching the instance; otherwise, CloudFormation will fail to create the stack due to a validation error.


The code as follows:
```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: >-
  AWS CloudFormation sample template LAMP_Single_Instance: Create a LAMP stack
  using a single EC2 instance and a local MySQL database for storage. This
  template demonstrates using the AWS CloudFormation bootstrap scripts to
  install the packages and files necessary to deploy the Apache web server, PHP,
  and MySQL at instance launch time. **WARNING** This template creates an Amazon
  EC2 instance. You will be billed for the AWS resources used if you create a
  stack from this template.
Parameters:
  KeyName:
    Description: Name of an existing EC2 KeyPair to enable SSH access to the instance
    Type: 'AWS::EC2::KeyPair::KeyName'
    ConstraintDescription: Can contain only ASCII characters.
  InstanceType:
    Description: WebServer EC2 instance type
    Type: String
    Default: t2.small
    AllowedValues:
      - t1.micro
      - t2.nano
      - t2.micro
      - t2.small
      - t2.medium
      - t2.large
      - m1.small
      - m1.medium
      - m1.large
      - m1.xlarge
      - m2.xlarge
      - m2.2xlarge
      - m2.4xlarge
      - m3.medium
      - m3.large
      - m3.xlarge
      - m3.2xlarge
      - m4.large
      - m4.xlarge
      - m4.2xlarge
      - m4.4xlarge
      - m4.10xlarge
      - c1.medium
      - c1.xlarge
      - c3.large
      - c3.xlarge
      - c3.2xlarge
      - c3.4xlarge
      - c3.8xlarge
      - c4.large
      - c4.xlarge
      - c4.2xlarge
      - c4.4xlarge
      - c4.8xlarge
      - g2.2xlarge
      - g2.8xlarge
      - r3.large
      - r3.xlarge
      - r3.2xlarge
      - r3.4xlarge
      - r3.8xlarge
      - i2.xlarge
      - i2.2xlarge
      - i2.4xlarge
      - i2.8xlarge
      - d2.xlarge
      - d2.2xlarge
      - d2.4xlarge
      - d2.8xlarge
      - hi1.4xlarge
      - hs1.8xlarge
      - cr1.8xlarge
      - cc2.8xlarge
      - cg1.4xlarge
    ConstraintDescription: must be a valid EC2 instance type.
  SSHLocation:
    Description: The IP address range that can be used to SSH to the EC2 instances
    Type: String
    MinLength: '9'
    MaxLength: '18'
    Default: 0.0.0.0/0
    AllowedPattern: '(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/(\d{1,2})'
    ConstraintDescription: Must be a valid IP CIDR range of the form x.x.x.x/x
Mappings:
  AWSInstanceType2Arch:
    t1.micro:
      Arch: HVM64
    t2.nano:
      Arch: HVM64
    t2.micro:
      Arch: HVM64
    t2.small:
      Arch: HVM64
    t2.medium:
      Arch: HVM64
    t2.large:
      Arch: HVM64
    m1.small:
      Arch: HVM64
    m1.medium:
      Arch: HVM64
    m1.large:
      Arch: HVM64
    m1.xlarge:
      Arch: HVM64
    m2.xlarge:
      Arch: HVM64
    m2.2xlarge:
      Arch: HVM64
    m2.4xlarge:
      Arch: HVM64
    m3.medium:
      Arch: HVM64
    m3.large:
      Arch: HVM64
    m3.xlarge:
      Arch: HVM64
    m3.2xlarge:
      Arch: HVM64
    m4.large:
      Arch: HVM64
    m4.xlarge:
      Arch: HVM64
    m4.2xlarge:
      Arch: HVM64
    m4.4xlarge:
      Arch: HVM64
    m4.10xlarge:
      Arch: HVM64
    c1.medium:
      Arch: HVM64
    c1.xlarge:
      Arch: HVM64
    c3.large:
      Arch: HVM64
    c3.xlarge:
      Arch: HVM64
    c3.2xlarge:
      Arch: HVM64
    c3.4xlarge:
      Arch: HVM64
    c3.8xlarge:
      Arch: HVM64
    c4.large:
      Arch: HVM64
    c4.xlarge:
      Arch: HVM64
    c4.2xlarge:
      Arch: HVM64
    c4.4xlarge:
      Arch: HVM64
    c4.8xlarge:
      Arch: HVM64
    g2.2xlarge:
      Arch: HVMG2
    g2.8xlarge:
      Arch: HVMG2
    r3.large:
      Arch: HVM64
    r3.xlarge:
      Arch: HVM64
    r3.2xlarge:
      Arch: HVM64
    r3.4xlarge:
      Arch: HVM64
    r3.8xlarge:
      Arch: HVM64
    i2.xlarge:
      Arch: HVM64
    i2.2xlarge:
      Arch: HVM64
    i2.4xlarge:
      Arch: HVM64
    i2.8xlarge:
      Arch: HVM64
    d2.xlarge:
      Arch: HVM64
    d2.2xlarge:
      Arch: HVM64
    d2.4xlarge:
      Arch: HVM64
    d2.8xlarge:
      Arch: HVM64
    hi1.4xlarge:
      Arch: HVM64
    hs1.8xlarge:
      Arch: HVM64
    cr1.8xlarge:
      Arch: HVM64
    cc2.8xlarge:
      Arch: HVM64
  AWSRegionArch2AMI:
    us-east-1:
      #HVM64: ami-0ff8a91507f77f867
      #HVM64: ami-0a0e5d9c7acc336f1
      HVM64: ami-09115b7bffbe3c5e4
      HVMG2: ami-0a584ac55a7631c0c
    us-west-2:
      HVM64: ami-a0cfeed8
      HVMG2: ami-0e09505bc235aa82d
    us-west-1:
      HVM64: ami-0bdb828fd58c52235
      HVMG2: ami-066ee5fd4a9ef77f1
    eu-west-1:
      HVM64: ami-047bb4163c506cd98
      HVMG2: ami-0a7c483d527806435
    eu-west-2:
      HVM64: ami-f976839e
      HVMG2: NOT_SUPPORTED
    eu-west-3:
      HVM64: ami-0ebc281c20e89ba4b
      HVMG2: NOT_SUPPORTED
    eu-central-1:
      HVM64: ami-0233214e13e500f77
      HVMG2: ami-06223d46a6d0661c7
    ap-northeast-1:
      HVM64: ami-06cd52961ce9f0d85
      HVMG2: ami-053cdd503598e4a9d
    ap-northeast-2:
      HVM64: ami-0a10b2721688ce9d2
      HVMG2: NOT_SUPPORTED
    ap-northeast-3:
      HVM64: ami-0d98120a9fb693f07
      HVMG2: NOT_SUPPORTED
    ap-southeast-1:
      HVM64: ami-08569b978cc4dfa10
      HVMG2: ami-0be9df32ae9f92309
    ap-southeast-2:
      HVM64: ami-09b42976632b27e9b
      HVMG2: ami-0a9ce9fecc3d1daf8
    ap-south-1:
      HVM64: ami-0912f71e06545ad88
      HVMG2: ami-097b15e89dbdcfcf4
    us-east-2:
      HVM64: ami-0b59bfac6be064b78
      HVMG2: NOT_SUPPORTED
    ca-central-1:
      HVM64: ami-0b18956f
      HVMG2: NOT_SUPPORTED
    sa-east-1:
      HVM64: ami-07b14488da8ea02a0
      HVMG2: NOT_SUPPORTED
    cn-north-1:
      HVM64: ami-0a4eaf6c4454eda75
      HVMG2: NOT_SUPPORTED
    cn-northwest-1:
      HVM64: ami-6b6a7d09
      HVMG2: NOT_SUPPORTED
Resources:
  WebServerInstance:
    Type: 'AWS::EC2::Instance'
    Properties:
      ImageId: !FindInMap 
        - AWSRegionArch2AMI
        - !Ref 'AWS::Region'
        - !FindInMap 
          - AWSInstanceType2Arch
          - !Ref InstanceType
          - Arch
      InstanceType: !Ref InstanceType
      SecurityGroups:
        - !Ref WebServerSecurityGroup
      KeyName: !Ref KeyName
  WebServerSecurityGroup:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: Enable HTTP access via port 80
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: !Ref SSHLocation
Outputs:
  WebsiteURL:
    Description: URL for newly created LAMP stack
    Value: !Join 
      - ''
      - - 'http://'
        - !GetAtt 
          - WebServerInstance
          - PublicDnsName

```

