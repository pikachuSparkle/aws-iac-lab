This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates). There are two methods that you could obtain the demo codes:

1. From the AWS templates GitHub:
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/VPC/
ll ./VPC_EC2_Instance_With_Multiple_Static_IPAddresses.yaml
```
2. From this repo
```
ll ./CloudFormation_Codes/VPC_EC2_Instance_With_Multiple_Static_IPAddresses.yaml
```

## Description

The provided AWS CloudFormation template demonstrates how to create an Amazon EC2 instance with a single network interface (ENI) that has multiple static private IP addresses in an existing VPC. Here is a detailed explanation of the key components and how it works.

#### **Parameters**: 
- The template accepts parameters such as:
    - `KeyName`: Existing EC2 KeyPair for SSH access.
    - `InstanceType`: EC2 instance type (default t3.micro).
    - `VpcId` and `SubnetId`: IDs of an existing VPC and subnet.
    - `PrimaryIPAddress` and `SecondaryIPAddress`: Two static private IPs assigned to the network interface.    
    - `SSHLocation`: CIDR range allowed to SSH into the instance.
    - `LatestAMI`: The AMI ID to use for the instance (default is the latest Amazon Linux 2 AMI).

#### **Resources**:
- **Network Interface (Eth0)**: Created with two private IP addresses, one primary and one secondary, attached to the specified subnet and associated with a security group allowing SSH access.
- **Elastic IP (EIP1)**: An Elastic IP is allocated and associated with the network interface Eth0. 
- **Security Group (SSHSecurityGroup)**: Allows inbound SSH (port 22) from the specified IP range.
- **EC2 Instance (EC2Instance)**: The instance is launched using the specified AMI, instance type, and key pair, and it uses the created network interface.

## How Multiple Static IPs Are Configured

- The network interface `Eth0` has two private IP addresses defined under `PrivateIpAddresses`:
    - `PrimaryIPAddress` marked as primary.
    - `SecondaryIPAddress` marked as secondary.
- This allows the EC2 instance to have multiple private IPs on a single ENI.
- An Elastic IP is associated with the primary private IP on the ENI to provide a public IP address.

## Important Notes

- Only one Elastic IP is associated in this template, attached to the single network interface. To have multiple public IPs, you would need multiple ENIs or additional Elastic IP associations on secondary private IPs with proper configuration
- The instance uses the latest Amazon Linux 2 AMI by default, but this can be overridden via the `LatestAMI` parameter.
- Security group only allows SSH access on port 22 from the specified `SSHLocation` CIDR.
- **An ENI stands for one networking interface on VM. We also can deploy multiple ENIs on one instance to implement multiple static ip address.**
## Summary

This CloudFormation template creates an EC2 instance with a single network interface configured with multiple static private IP addresses within an existing VPC and subnet. It also associates an Elastic IP with the network interface for public access. 

The template is useful for scenarios where an instance needs multiple private IPs on one interface, such as hosting multiple services or applications requiring distinct IPs. However, for multiple public IPs, additional ENIs or Elastic IP associations are needed beyond this example.

This approach aligns with AWS best practices for managing multiple IP addresses on EC2 instances and leveraging CloudFormation for repeatable infrastructure deployment.