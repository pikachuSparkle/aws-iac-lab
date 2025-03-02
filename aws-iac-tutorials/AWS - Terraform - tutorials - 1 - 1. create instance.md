## References:
https://www.youtube.com/watch?v=SLB_c_ayRMo

## Create EC2 instances

```shell
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
cd aws-iac-lab/Terraform_Codes/terraform-tutorials/01_aws_instance/
terraform init 
terraform apply
```

```shell
terraform destroy
```

```terraform
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
  # access_key and secret_key are removed to use the AWS credentials file
}

# Create a EC2 instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "my-first-server" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t2.micro"

  tags = {
    Name = "tag-my-first-server"
  }
}

```