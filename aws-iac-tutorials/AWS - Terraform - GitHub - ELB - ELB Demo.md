This example is based on the GitHub repo [terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws/blob/main/examples/elb). TThe example launches a web server, installs nginx, creates an ELB for instance. It also creates security groups for the ELB and EC2 instance.

The former AMI is too old and  is out of DeprecationTime. The nginx welcome page can not be accessed. In this case, we replace with ubuntu-22.04 AMI and works well. [official repo PR](https://github.com/hashicorp/terraform-provider-aws/pull/42153)

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
cd ./examples/elb/
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
  value = aws_elb.web.dns_name
}
```
output
```
address = "example-elb-********.us-east-1.elb.amazonaws.com"
```
Visit `http://address` && get the welcome page


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
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf_test"
  }
}

resource "aws_subnet" "tf_test_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_test_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "tf_test_ig"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf_test_subnet.id
  route_table_id = aws_route_table.r.id
}
```

This Terraform script configures basic network resources in AWS, providing a Virtual Private Cloud (VPC), a subnet, an Internet Gateway, and a route table for external connectivity. Here's a breakdown:

1. **VPC (**`aws_vpc`**)**:
    - **CIDR Block**: The VPC will use `10.0.0.0/16` as its IP address range.
    - **Enable DNS Hostnames**: Allows instances to receive DNS hostnames.
    - **Tags**: Name the VPC as `tf_test`.
        
2. **Subnet (**`aws_subnet`**)**:
    - **CIDR Block**: The subnet will use `10.0.0.0/24`, carving out a portion of the VPC's IP address range.
    - **Map Public IPs on Launch**: Automatically assigns public IPs to instances created within this subnet.
    - **Tags**: Name the subnet as `tf_test_subnet`.
        
3. **Internet Gateway (**`aws_internet_gateway`**)**:
    - Attaches to the VPC to enable internet connectivity.
    - **Tags**: Named `tf_test_ig`.

4. **Route Table (**`aws_route_table`**)**:    
    - Adds a route allowing all outbound traffic (`0.0.0.0/0`) to go through the Internet Gateway.
    - **Tags**: Named `aws_route_table`.
        
5. **Route Table Association (**`aws_route_table_association`**)**:
    - Links the route table to the subnet, ensuring resources within the subnet use the defined routing rules.

This configuration sets up a basic networking environment in AWS for publicly accessible resources. 

## Release Resources
```
terraform destroy
```