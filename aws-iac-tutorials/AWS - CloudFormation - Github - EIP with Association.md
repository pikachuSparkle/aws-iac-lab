## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates)

There are two methods that you could obtain the demo codes:
1. From the AWS templates GitHub: [InstanceWithCfnInit.yaml](https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/EC2/InstanceWithCfnInit.yaml "InstanceWithCfnInit.yaml")
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/EC2/
ll ./EIP_With_Association.yaml
```
2. From this repo
```
./CloudFormation_Codes/EIP_With_Association.yaml
```


## Description

The provided CloudFormation YAML template is designed to create an Amazon EC2 instance and associate it with an Elastic IP (EIP) address.

This template can be used to quickly deploy an EC2 instance with an Elastic IP address, ensuring consistent access to the instance regardless of its private IP address. It's particularly useful for web servers or other applications requiring a static public IP address.

This template shows how to associate an Elastic IP address with an Amazon EC2 instance - you can use this same technique to associate an EC2 instance with an Elastic IP Address that is not created inside the template by replacing the EIP reference in the AWS::EC2::EIPAssoication resource type with the IP address of the external EIP. 

**WARNING:** 
This template creates an Amazon EC2 instance and an Elastic IP Address. You will be billed for the AWS resources used if you create a stack from this template.

## Parameters

These are dynamic values that can be specified when creating or updating a stack:

- **InstanceType**: Allows users to choose the type of EC2 instance, with a default value of "t3.small".
- **KeyName**: Specifies the name of an existing EC2 key pair for SSH access.
- **SSHLocation**: Defines the IP address range allowed for SSH access, defaulting to "0.0.0.0/0".
- **LatestAmiId**: Retrieves the latest Amazon Linux 2 AMI ID from AWS Systems Manager (SSM).
- **Subnets**: A list of subnet IDs where the EC2 instance will be launched.

## Resources

These are the AWS resources created by the template:
- **EC2Instance**: An EC2 instance with properties like instance type, subnet ID, security group IDs, key name, and image ID.
- **InstanceSecurityGroup**: A security group allowing SSH access from the specified IP range.
- **IPAddress**: An Elastic IP address.
- **IPAssoc**: An association between the Elastic IP address and the EC2 instance.

## Outputs

These provide values that can be retrieved after stack creation:
- **InstanceId**: The ID of the newly created EC2 instance.
- **InstanceIPAddress**: The Elastic IP address associated with the EC2 instance.

## Key Points

- **Elastic IP Association**: The template uses `AWS::EC2::EIPAssociation` to associate the Elastic IP with the EC2 instance. The `AllocationId` is obtained from the `IPAddress` resource.
- **Security Group**: The template creates a security group allowing SSH access from a specified IP range.
- **Dynamic AMI Selection**: The template uses an SSM parameter to fetch the latest Amazon Linux 2 AMI ID.
- **SecurityGroupIds**: Only Security Group id can be allowed, and `!GetAtt InstanceSecurityGroup.GroupId`