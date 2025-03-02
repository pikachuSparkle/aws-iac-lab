## References:
https://www.youtube.com/watch?v=SLB_c_ayRMo


## Command

```shell
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
cd aws-iac-lab/Terraform_Codes/terraform-tutorials/04_aws_demo_variables/
terraform init 
terraform apply
```

```shell
terraform destroy
```


## Variables Demo

```
NOTES: Pay attention to the variables `subnet_profix`
```

`main.tf`
```
variable "subnet_profix" {
  description = "Subnet prefix"
  type        = string
}
```

`terraform.tfvars`
```
subnet_profix = "10.0.2.0/24"
```

## Resolve EIP provision fail problem

```
# 8. Assign an elastic IP
# associate with the network interface, associate_with_private_ip
# wait internet gateway to be created
# wait for the instance to be created
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.2.4"
  depends_on = [aws_internet_gateway.prod-gw,null_resource.wait_for_instance]
  # Note: EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
}

...

# 10. Wait for the instance to be in running state
resource "null_resource" "wait_for_instance" {
  provisioner "local-exec" {
    command = "echo Waiting for instance to be ready..."
  }

  triggers = {
    instance_id = aws_instance.web-server-instance.id
  }
}
```