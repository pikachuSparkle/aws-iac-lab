This example is based on the GitHub repo [terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws/tree/main/examples/asg). And it shows how to launch instances using Auto Scaling Groups. 
At the same time, an "Launch Configuration deprecated problem" has been fixed in this article. And the fixed codes has been committed to [official repo PR](https://github.com/hashicorp/terraform-provider-aws/pull/42068) and been merged.

Error info
```
Error: creating Auto Scaling Launch Configuration (terraform-example-lc): operation error Auto Scaling: CreateLaunchConfiguration, https response error StatusCode: 400, RequestID: 3b44fccd-736e-4417-9fbf-d612a1d843aa, api error UnsupportedOperation: The Launch Configuration creation operation is not available in your account. Use launch templates to create configuration templates for your Auto Scaling groups.
│ 
│   with aws_launch_configuration.web-lc,
│   on main.tf line 56, in resource "aws_launch_configuration" "web-lc":
│   56: resource "aws_launch_configuration" "web-lc" {
```
## References:
https://github.com/hashicorp/terraform-provider-aws/blob/main/examples/asg
https://github.com/hashicorp/terraform-provider-aws/pull/42068
[[AWS - Terraform - Tutorial - ASG - Manage AWS Auto Scaling Groups]]

AWS provider resource docs
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template


## Source Code Retrieving

Two methods to validate the codes:
1. Obtain from official GitHub repo
```shell
git clone https://github.com/hashicorp/terraform-provider-aws.git
cd terraform-provider-aws/examples/asg/
# Check the region and other resources
vim main.tf 
vim variables.tf
vim outputs.tf

terraform init
terraform apply
# input your key pair to apply the codes
```
2. Check my personal GitHub repo 
```shell
git clone https://github.com/pikachuSparkle/terraform-provider-aws.git
cd terraform-provider-aws/examples/asg/
# Check the region and other resources
vim main.tf 
vim variables.tf
vim outputs.tf

terraform init
terraform apply
# input your key pair to apply the codes
```

## Code Review

```
resource "aws_launch_template" "web-lt" {
  name          = "terraform-example-lt"
  image_id      = var.aws_amis[var.aws_region]
  instance_type = var.instance_type

  # Security group
  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = base64encode(file("userdata.sh"))
  key_name               = var.key_name
}
```

This Terraform configuration defines a resource of type `aws_launch_template` named `web-lt`. Let's break it down step by step:
1. **Resource Type and Name:**
    - `resource "aws_launch_template" "web-lt"`: This creates an Amazon EC2 Launch Template, which helps define instance configurations in AWS.
2. **Basic Attributes:**
    - `name = "terraform-example-lt"`: Sets the name of the launch template to `terraform-example-lt`.
    - `image_id = var.aws_amis[var.aws_region]`: Specifies the Amazon Machine Image (AMI) ID for the instances. It references a variable `aws_amis` that varies based on the AWS region.
    - `instance_type = var.instance_type`: Defines the instance type (e.g., `t2.micro`, `m5.large`), referencing a variable `instance_type`.
3. **Security Group:**
    - `vpc_security_group_ids = [aws_security_group.default.id]`: Associates the instance with a security group. It references the ID of another resource, `aws_security_group.default`.
4. **User Data:**
    - `user_data = base64encode(file("userdata.sh"))`: Supplies a script (`userdata.sh`) as Base64-encoded user data for configuring instances during launch. This might include setup commands or scripts.
5. **SSH Key:**
    - `key_name = var.key_name`: Associates the instances with an SSH key pair defined by the variable `key_name`.


```
resource "aws_autoscaling_group" "web-asg" {
  availability_zones = local.availability_zones
  name               = "terraform-example-asg"
  max_size           = var.asg_max
  min_size           = var.asg_min
  desired_capacity   = var.asg_desired
  force_delete       = true
  launch_template {
    id      = aws_launch_template.web-lt.id
    version = aws_launch_template.web-lt.latest_version
  }
  load_balancers = [aws_elb.web-elb.name]

  #vpc_zone_identifier = ["${split(",", var.availability_zones)}"]
  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = "true"
  }
}
```

This Terraform configuration defines an **AWS Auto Scaling Group** resource named `web-asg`. Here's what each part means:
1. **Resource Definition:**
    - `resource "aws_autoscaling_group" "web-asg"`: This creates an Auto Scaling Group in AWS that manages EC2 instances and ensures scalability based on demand.
2. **Basic Attributes:**
    - `availability_zones = local.availability_zones`: Specifies the availability zones where instances can be launched, sourced from a local variable.
    - `name = "terraform-example-asg"`: Sets the name of the Auto Scaling Group to `terraform-example-asg`.
    - `max_size = var.asg_max`: Defines the maximum number of EC2 instances that can be scaled up in the group, referencing a variable `asg_max`.
    - `min_size = var.asg_min`: Sets the minimum number of instances to maintain in the group, referencing the variable `asg_min`.
    - `desired_capacity = var.asg_desired`: Defines the desired number of instances to run, sourced from the variable `asg_desired`.
    - `force_delete = true`: Ensures the Auto Scaling Group can be deleted, even if there are existing instances in it.
3. **Launch Template:**
    - `launch_template {}`: Configures the Auto Scaling Group to use an **AWS Launch Template**. It references the launch template created earlier (`aws_launch_template.web-lt`) and uses its latest version.
4. **Load Balancer:**
    - `load_balancers = [aws_elb.web-elb.name]`: Associates the Auto Scaling Group with an Elastic Load Balancer (ELB) named `web-elb`, enabling traffic distribution among instances.
5. **Tags:**
    - `tag {}`: Defines a tag with:
        - `key = "Name"`: The tag key, which is "Name".
        - `value = "web-asg"`: The tag value, "web-asg".
        - `propagate_at_launch = "true"`: Ensures the tag is applied to instances launched by the Auto Scaling Group.
6. **Commented Code:**
    - `#vpc_zone_identifier = ["${split(",", var.availability_zones)}"]`: This commented-out line might indicate an alternative way to specify subnets where instances can be launched.

## Validate the results

According to the `Outputs`, visit the endpoint with chrome browser & you will get the nginx welcome page.
```
http://terraform-example-elb-**********.us-east-1.elb.amazonaws.com
```

