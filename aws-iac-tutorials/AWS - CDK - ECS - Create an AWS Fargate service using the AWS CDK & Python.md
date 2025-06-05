## DOCS

https://docs.aws.amazon.com/cdk/v2/guide/ecs-example.html

>NOTES: 
>This is the AWS CDK v2 Developer Guide. The older CDK v1 entered maintenance on June 1, 2022 and ended support on June 1, 2023.

## Abstraction
This example shows how to create an AWS Fargate service running on an Amazon Elastic Container Service (Amazon ECS) cluster that’s fronted by an internet-facing Application Load Balancer from an image on Amazon ECR.

This example creates a similar Fargate service using the AWS CDK.

The Amazon ECS construct used in this example helps you use AWS services by providing the following benefits:
- Automatically configures a load balancer.
- Automatically opens a security group for load balancers. This enables load balancers to communicate with instances without having to explicitly create a security group.
- Automatically orders dependency between the service and the load balancer attaching to a target group, where the AWS CDK enforces the correct order of creating the listener before an instance is created.
- Automatically configures user data on automatically scaling groups. This creates the correct configuration to associate a cluster to AMIs.
- Validates parameter combinations early. This exposes AWS CloudFormation issues earlier, thus saving deployment time. For example, depending on the task, it’s easy to improperly configure the memory settings. Previously, we would not encounter an error until we deployed our app. But now the AWS CDK can detect a misconfiguration and emit an error when we synthesize our app.
- Automatically adds permissions for Amazon Elastic Container Registry (Amazon ECR) if we use an image from Amazon ECR.
- Automatically scales. The AWS CDK supplies a method so we can auto scale instances when we use an Amazon EC2 cluster. This happens automatically when we use an instance in a Fargate cluster. In addition, the AWS CDK prevents an instance from being deleted when automatic scaling tries to stop an instance, but either a task is running or is scheduled on that instance. Previously, we had to create a Lambda function to have this functionality.
- Provides asset support, so that we can deploy a source from our machine to Amazon ECS in one step. Previously, to use an application source, we had to perform several manual steps, such as uploading to Amazon ECR and creating a Docker image.

## Prerequisites

- Node.js 22.16.0
- Python 3.11.8
- pip 24.0
- Windows 10
- VS Code
## Create a CDK project

Install CDK tool globally.
```shell
node -v
npm -v
npm install -g aws-cdk
cdk --version
```

We start by creating a CDK project. This is a directory that stores our AWS CDK code, including our CDK app.
```shell
mkdir MyEcsConstruct 
cd MyEcsConstruct 
cdk init --language python 

source .venv/bin/activate 
# On Windows, run '.\venv\Scripts\activate' instead 
# deactivate

pip install -r requirements.txt 
# pip install aws-cdk-lib constructs
```

Next, we run the app and confirm that it creates an empty stack.
```shell
cdk synth
```

## Create a Fargate service

There are two different ways that we can run our container tasks with Amazon ECS:
- Use the `Fargate` launch type, where Amazon ECS manages the physical machines that oour containers are running on for us.
- Use the `EC2` launch type, where we do the managing, such as specifying automatic scaling.

For this example, we’ll create a Fargate service running on an Amazon ECS cluster, fronted by an internet-facing Application Load Balancer.

We add the following AWS Construct Library module imports to our _stack file_:

File: `my_ecs_construct/my_ecs_construct_stack.py`
```
from aws_cdk import (aws_ec2 as ec2, aws_ecs as ecs, aws_ecs_patterns as ecs_patterns)
```

Within our stack, we add the following code:
```
vpc = ec2.Vpc(self, "MyVpc", max_azs=3) # default is all AZs in region 

cluster = ecs.Cluster(self, "MyCluster", vpc=vpc) 

ecs_patterns.ApplicationLoadBalancedFargateService(self, "MyFargateService",
    cluster=cluster, # Required 
    cpu=512, # Default is 256 
    desired_count=6, # Default is 1
    task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions( image=ecs.ContainerImage.from_registry("amazon/amazon-ecs-sample")), 
    memory_limit_mib=2048, # Default is 512 
    public_load_balancer=True) # Default is True
```

Official DOCS:
- https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.aws_ecs_patterns.ApplicationLoadBalancedFargateService.html
- https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_ecs_patterns/ApplicationLoadBalancedFargateService.html

Next, we validate our code by running the following to synthesize our stack:
```
cdk synth
```

Install awscli
```shell
pip install awscli
```
https://github.com/aws/aws-cli/issues/5990

Configure credentials
```shell
aws configure
```

```shell
cdk bootstrap aws://ACCOUNT-NUMBER/REGION
```

```shell
cdk deploy
```

## Validate

Check the output:
```
MyFargateServiceLoadBalancerDNS
MyEcsC-MyFar-**************************.us-east-1.elb.amazonaws.com
```

```
MyFargateServiceServiceURL
http://MyEcsC-MyFar-*******************.us-east-1.elb.amazonaws.com
```

Visit `MyFargateServiceServiceURL` with Chrome. Shows as follows:
```
Simple PHP App
Congratulations
Your PHP application is now running on a container in Amazon ECS.

The container is running PHP version 5.4.16.
```

## Clean up

As a general maintenance best practice, and to minimize unnecessary costs, we delete our stack when complete:
```
cdk destroy
```
