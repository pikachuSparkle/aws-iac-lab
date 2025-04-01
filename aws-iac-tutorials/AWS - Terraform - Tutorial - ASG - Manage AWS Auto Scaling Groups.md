
## Get Started and Fix Source Bugs

This tutorial is based on hashicorp official DOCS [ASG tutorial for AWS services](https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg) and  [GitHub](https://github.com/hashicorp-education/learn-terraform-aws-asg)

But as the time flows, there is some new problems need to be fixed as follows:
1. AMI "amzn-ami-hvm-*-x86_64-ebs" no longer exists
2. Resource `aws_launch_configuration` not supported in AWS from **October 1, 2024**. You can reference the [AWS official DOCS](https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-configurations.html)

In this tutorial, the above problems have been resolved. And you have two methods to deploy the codes and validate.
1. Obtain from my GitHub repo:
```shell
git clone https://github.com/pikachuSparkle/learn-terraform-aws-asg.git
cd learn-terraform-aws-asg
vim main.tf # Check the region and other resources
terraform init
terraform apply
```
2. Check the hashicorp official GitHub repo and fix the problem manually. I have commit the [fixed codes](https://github.com/hashicorp-education/learn-terraform-aws-asg/pull/20)

## Validate

Outputs:
```
application_endpoint = "http://learn-asg-terramino-lb-1572171601.us-east-1.elb.amazonaws.com/index.php"

asg_name = "terramino"

lb_endpoint = "http://learn-asg-terramino-lb-1572171601.us-east-1.elb.amazonaws.com"
```

Visit `application_endpoint` and `lb_endpoint` with your browser.

&& 

Use `cURL` to send a request to the `lb_endpoint` output, which reports the instance ID of the EC2 instance responding to your request.

```
$ curl $(terraform output -raw lb_endpoint)
i-0735ecca64f49e5e1
```

Then, visit the address in the `application_endpoint` output value in your browser to test out your application.

## Review configuration

In your code editor, open the `main.tf` file to review the configuration in this repository.

#### Search your AMI

With aws command utility, you can search specified AMI with following shell scripts. 
```shell
aws ec2 describe-images --owners 'amazon' --query 'Images[*].[ImageId,Name,CreationDate]' --filters "Name=name,Values=amzn-ami-*"  --output json
```

```shell
aws ec2 describe-images --owners 'amazon' --query 'Images[*].[ImageId,Name,CreationDate]' --filters "Name=name,Values=al2023-ami-2023.6.20250218.2-kernel-6.1-x86_64"  --output json
```

```
data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*"]
  }
}
```

Here, AMI `amzn-ami-2018.03.20250224-amazon-ecs-optimized` will be used in the end, which is a Amazon Linux 2 based OS and especially optimized for **Amazon ECS（ Elastic Container Service )** features.

#### EC2 Launch Template

A **launch template** specifies the EC2 instance configuration that an ASG will use to launch each new instance.

Resource aws_launch_configuration are not supported in AWS now. You can reference terraform aws provider documents:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
It offers the knowledge of how to configure a EC2 Template for ASG.
```
resource "aws_launch_template" "terramino" {
  name_prefix = "learn-terraform-aws-asg-"
  image_id = data.aws_ami.amazon-linux.id
  instance_type = "t2.micro"
  user_data = base64encode(file("user-data.sh"))
  vpc_security_group_ids = [aws_security_group.terramino_instance.id]

  # Optional: You can specify additional settings like key_name, monitoring, etc.
  # key_name = "your_key_name"
  # lifecycle {
  #   create_before_destroy = true
  # }
}

```

- a user data script, which configures the instances to run the `user-data.sh` file in this repository at launch time. The user data script installs dependencies and initializes Terramino, a Terraform-skinned Tetris application.
- an Amazon Linux AMI specified by a data source.
- a security group to associate with the instances. The security group (defined later in this file) allows ingress traffic on port 80 and egress traffic to all endpoints.

You cannot modify a launch configuration, so any changes to the definition force Terraform to create a new resource. The `create_before_destroy` argument in the `lifecycle` block instructs Terraform to create the new version before destroying the original to avoid any service interruptions.

```
NOTES:
In AWS EC2, user data scripts are executed by `cloud-init` during the first boot of an instance. Typically, `cloud-init` runs as the `root` user. This means that any `user-data.sh` script specified in your `aws_launch_template` resource will also be executed as the `root` user.
```


#### Auto Scaling group

An ASG is a logical grouping of EC2 instances running the same configuration. ASGs allow for dynamic scaling and make it easier to manage a group of instances that host the same services.

In the following documentation, you will know how to reference EC2 template resource.
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
```
resource "aws_autoscaling_group" "terramino" {
  name                 = "terramino"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  
  # Refer to aws_launch_template
  launch_template {
    id      = aws_launch_template.terramino.id
    version = aws_launch_template.terramino.latest_version
  }
  
  vpc_zone_identifier  = module.vpc.public_subnets

  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "HashiCorp Learn ASG - Terramino"
    propagate_at_launch = true
  }
}
```

This ASG configuration sets:
- a list of subnets where the ASGs will launch new instances. This configuration references the public subnets created by the `vpc` module.

#### Load balancer resources

Since you will launch multiple instances running your Terramino application, you must provision a load balancer to distribute traffic across the instances.

```
http/https ----> aws_lb_listener ----> aws_lb ----> aws_lb_target_group
```
The `aws_lb` resource creates an application load balancer, which routes traffic at the application layer.

main.tf
```
resource "aws_lb" "terramino" {
  name               = "learn-asg-terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terramino_lb.id]
  subnets            = module.vpc.public_subnets
}
```

The [`aws_lb_listener` resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) specifies how to handle any HTTP requests to port `80`. In this case, it forwards all requests to the load balancer to a target group. You can define multiple listeners with distinct listener rules for more complex traffic routing.

main.tf
```
resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.terramino.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terramino.arn
  }
}
```

A target group defines the collection of instances your load balancer sends traffic to. It does not manage the configuration of the targets in that group directly, but instead specifies a list of destinations the load balancer can forward requests to.

main.tf
```
 resource "aws_lb_target_group" "terramino" {
   name     = "learn-asg-terramino"
   port     = 80
   protocol = "HTTP"
   vpc_id   = module.vpc.vpc_id
 }

resource "aws_autoscaling_attachment" "terramino" {
  autoscaling_group_name = aws_autoscaling_group.terramino.id
  alb_target_group_arn   = aws_lb_target_group.terramino.arn
}
```

While you can use an [`aws_lb_target_group_attachment` resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) to directly associate an EC2 instance or other target type with the target group, the dynamic nature of instances in an ASG makes that hard to maintain in configuration. Instead, this configuration links your Auto Scaling group with the target group using the `aws_autoscaling_attachment` resource. This allows AWS to automatically add and remove instances from the target group over their lifecycle.

