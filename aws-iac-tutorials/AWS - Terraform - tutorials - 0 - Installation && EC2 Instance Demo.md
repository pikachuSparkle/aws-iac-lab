## References

[AWS | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)

## Install Terraform & AWS CLI

terraform installation
```shell
# download bionary URL
wget https://releases.hashicorp.com/terraform/1.9.2/terraform_1.9.2_linux_amd64.zip
unzip terraform_1.9.2_linux_amd64.zip
mv ./terraform /usr/local/bin/
echo $PATH  #一般来说在环境变量的$PATH里面
terraform -help
terraform -help plan
```
 
aws cli installation
```shell
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
cd /usr/local/bin
aws version
```

```shell
# config environment variables or config ~/.aws/credentials and ~/.aws/config
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```
## EC2 Instance Demo

```shell
mkdir learn-terraform-aws-instance
cd learn-terraform-aws-instance
touch main.tf
```

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

resource "aws_instance" "app_server" {
  ami           = "ami-830c*******94e3"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

```

## EC2 Instance Demo with Security Group

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

The `data` keyword in Terraform is used to fetch information about resources that are not managed by Terraform itself. In this case, it's used to retrieve details about an existing AWS security group.
## Commands demo

```shell
terraform init
terraform fmt
terraform validate
terraform apply
terraform show
terraform state
terraform state list
```
