## References:
https://www.youtube.com/watch?v=SLB_c_ayRMo

## Create VPC

main.tf
```
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = "YYYYYYYYYYYYYYYYYYY"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

# Create a VPC
# https://registry.terraform.io/providers/hashicorp/aws/5.69.0/docs/resources/vpc
resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tag-Prod-vpc"
  }
}


# Create a subnet
# https://registry.terraform.io/providers/hashicorp/aws/5.69.0/docs/resources/subnet
resource "aws_subnet" "first-subnet" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "tag-Prod-subnet"
  }
}


# Create a EC2 instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "first-server" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t2.micro"

  tags = {
    Name = "tag-Prod-instance"
  }
}

```