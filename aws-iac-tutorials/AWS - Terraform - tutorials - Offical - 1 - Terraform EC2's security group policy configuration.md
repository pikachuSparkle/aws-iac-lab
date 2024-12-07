

在demo的基础上调整group policy，以便于访问
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}


data "aws_security_group" "launch_wizard_1" {
  name = "launch-wizard-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.launch_wizard_1.id]

  tags = {
    Name = "Example2-EC2"
  }
}

```
