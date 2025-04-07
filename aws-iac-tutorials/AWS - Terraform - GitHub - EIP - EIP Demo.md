This example is based on the GitHub repo [terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws/blob/main/examples/eip). The eip example launches a web server, installs nginx. It also creates security group.

The former AMI is too old and  is out of DeprecationTime. The nginx welcome page can not be accessed. In this case, we replace with ubuntu-22.04 AMI and works well. [official repo PR](https://github.com/hashicorp/terraform-provider-aws/pull/42104)

```
# ubuntu-jammy-22.04 (amd64)
variable "aws_amis" {
  default = {
    "us-east-1" = "ami-005fc0f236362e99f"
    "us-west-2" = "ami-0075013580f6322a1"
  }
}
```
## Obtain the source code

```
git clone https://github.com/pikachuSparkle/terraform-provider-aws.git
cd ./examples/eip/
ll
```

```
terraform init
terraform apply
```

## Validate

outputs.tf
```
output "address" {
  value = aws_instance.web.private_ip
}

output "elastic_ip" {
  value = aws_eip.default.public_ip
}
```

Visit `http://public_ip` && get the welcome page

Check the instance info -- `IMDSv2`（Instance Metadata Service Version 2）

command:
```
curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
```

```
export TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

```
curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/"
```

output:
```
ami-id
ami-launch-index
ami-manifest-path
block-device-mapping/
events/
hibernation/
hostname
identity-credentials/
instance-action
instance-id
instance-life-cycle
instance-type
local-hostname
local-ipv4
mac
managed-ssh-keys/
metrics/
network/
placement/
profile
public-hostname
public-ipv4
public-keys/
reservation-id
security-groups
services/
system
```

command:
```
curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/ami-id"
```

output:
```
ami-005fc0f236362e99f
```



## Code Review

```
resource "aws_eip" "default" {
  instance = aws_instance.web.id
  domain   = "vpc"
}
```

This code snippet is a Terraform configuration for creating an AWS Elastic IP (EIP) and associating it with an EC2 instance within a Virtual Private Cloud (VPC). Here's an explanation of its components:

#### Breakdown:
1. `resource "aws_eip" "default"`:
    - This defines a new AWS Elastic IP resource named `default`.
    - Elastic IPs are static public IP addresses that you can associate with your AWS resources.    
2. `instance = aws_instance.web.id`:
    - Associates the Elastic IP with the EC2 instance identified by `aws_instance.web.id`.
    - `aws_instance.web.id` refers to the ID of a previously defined EC2 instance named `web` in the Terraform configuration.
3. `domain = "vpc"`:
    - Specifies that the Elastic IP will be allocated in the "vpc" domain, which is necessary when associating it with instances in a VPC.
    - The `"vpc"` domain ensures that the EIP is compatible with VPC-based resources.

#### Purpose:
- The code binds a static Elastic IP to the EC2 instance named `web`, enabling the instance to maintain the same public IP address even if it is stopped or restarted.
- It ensures consistent connectivity for services hosted on the instance, particularly useful when you require a fixed public IP for accessing or configuring external services.

## Release Resources

```
terraform destroy
```