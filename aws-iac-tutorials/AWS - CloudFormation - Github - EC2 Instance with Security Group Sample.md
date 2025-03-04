## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates)

There are two methods that you could obtain the demo codes:
1. From the AWS templates GitHub: [InstanceWithCfnInit.yaml](https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/EC2/InstanceWithCfnInit.yaml "InstanceWithCfnInit.yaml")
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/EC2/
ll ./EC2InstanceWithSecurityGroupSample.yaml
```
2. From this repo
```
./CloudFormation_Codes/EC2InstanceWithSecurityGroupSample.yaml
```


## Description:

The provided CloudFormation YAML template is designed to create an Amazon EC2 instance and a security group that allows SSH access.

This template can be used to quickly deploy an EC2 instance with SSH access restricted to a specific IP range, ensuring secure access to the instance.

Create an Amazon EC2 instance running the Amazon Linux AMI. The AMI is chosen based on the region in which the stack is run. This example creates an EC2 security group for the instance to give you SSH access. 

**WARNING:** 
This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.


## Parameters

These are dynamic values that can be specified when creating or updating a stack:
- **KeyName**: Specifies the name of an existing EC2 key pair for SSH access.
- **InstanceType**: Allows users to choose the type of EC2 instance to create, with a default value of "t3.small".
- **SSHLocation**: Defines the IP address range allowed for SSH access, defaulting to "192.168.1.0/0". However, this default value is incorrect as it should be a valid IP CIDR range (e.g., "192.168.1.0/24").
- **LatestAmiId**: Retrieves the latest Amazon Linux 2 AMI ID from AWS Systems Manager (SSM).
- **Subnets**: A list of subnet IDs where the EC2 instance will be launched.


## Resources

These are the AWS resources created by the template:
- **EC2Instance**: An EC2 instance with properties like instance type, subnet ID, security group IDs, key name, and image ID.
- **InstanceSecurityGroup**: A security group allowing SSH access from the specified IP range.


## Outputs

These provide values that can be retrieved after stack creation:
- **InstanceId**: The ID of the newly created EC2 instance.
- **AZ**: The Availability Zone of the EC2 instance.
- **PublicDNS**: The public DNS name of the EC2 instance.
- **PublicIP**: The public IP address of the EC2 instance.

## Key Points

- **Security Group Configuration**: The template creates a security group that allows SSH access (port 22) from the IP range specified by the `SSHLocation` parameter.
- **EC2 Instance Configuration**: The instance is launched with the specified instance type, key pair, and AMI.
- **Subnet Selection**: The instance is placed in the first subnet listed in the `Subnets` parameter.