## DOCS

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_Fargate.html

## Prerequisites

- The latest version of the AWS CLI is installed and configured.
- The steps in [Set up to use Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html) have been completed.
- Your IAM user has the required permissions specified in the [AmazonECS_FullAccess](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonECS_FullAccess) IAM policy example.
- You have a VPC and security group created to use. This tutorial uses a container image hosted on Amazon ECR Public so your task must have internet access. To give your task a route to the internet, use one of the following options.
    - Use a private subnet with a NAT gateway that has an elastic IP address.
    - Use a public subnet and assign a public IP address to the task.
- (Optional) AWS CloudShell is a tool that gives customers a command line without needing to create their own EC2 instance.
- If you follow this tutorial using a private subnet, you can use Amazon ECS Exec to directly interact with your container and test the deployment. You will need to create a task IAM role to use ECS Exec. 

After you create the role, add additional permissions to the role for the following features.

| Feature                                           | Additional permissions                                                                                                                                         |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Use ECS Exec                                      | [ECS Exec permissions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#ecs-exec-required-iam-permissions)                      |
| Use an image from a private Amazon ECR repository | [Amazon ECR permissions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#ecr-required-iam-permissions)                         |
| Use EC2 instances (Windows and Linux)             | [Amazon EC2 instances additional configuration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#task-iam-role-considerations)  |
| Use external instances                            | [External instance additional configuration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#enable_task_iam_roles)            |
| Use Windows EC2 instances                         | [Amazon EC2 Windows instance additional configuration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#windows_task_IAM_roles) |

## Step 1: Create a Cluster

```
aws ecs create-cluster --cluster-name fargate-cluster
```
## Step 2: Register a Linux Task Definition

```
vim ./fargate-task.json
```

```
 {
        "family": "sample-fargate",
        "networkMode": "awsvpc",
        "taskRoleArn": "arn:aws:iam::aws_account_id:role/ecsTaskExecutionRole", 
        "containerDefinitions": [
            {
                "name": "fargate-app",
                "image": "public.ecr.aws/docker/library/httpd:latest",
                "portMappings": [
                    {
                        "containerPort": 80,
                        "hostPort": 80,
                        "protocol": "tcp"
                    }
                ],
                "essential": true,
                "entryPoint": [
                    "sh",
                    "-c"
                ],
                "command": [
                    "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
                ]
            }
        ],
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "cpu": "256",
        "memory": "512"
}
```

```
aws ecs register-task-definition --cli-input-json file://./fargate-task.json
```

## Step 3: List Task Definitions

```
aws ecs list-task-definitions
```
## Step 4: Create a Service

After you have registered a task for your account, you can create a service for the registered task in your cluster. For this example, you create a service with one instance of the `sample-fargate:1` task definition running in your cluster. The task requires a route to the internet, so there are two ways you can achieve this. One way is to use a private subnet configured with a NAT gateway with an elastic IP address in a public subnet. Another way is to use a public subnet and assign a public IP address to your task. We provide both examples below.

Example using a public subnet.
```
aws ecs create-service --cluster fargate-cluster --service-name fargate-service --task-definition sample-fargate:1 --desired-count 1 --launch-type "FARGATE" --network-configuration "awsvpcConfiguration={subnets=[subnet-abcd1234],securityGroups=[sg-abcd1234],assignPublicIp=ENABLED}"
```

## Step 5: List Services

```
aws ecs list-services --cluster fargate-cluster
```


## Step 6: Describe the Running Service

Describe the service using the service name retrieved earlier to get more information about the task.
```
aws ecs describe-services --cluster fargate-cluster --services fargate-service
```

## Step 7: Test & Validate
#### Testing task deployed using public subnet
Describe the task in the service so that you can get the Elastic Network Interface (ENI) for the task.

First, get the task ARN.
```
aws ecs list-tasks --cluster fargate-cluster --service fargate-service
```

Output
```
{ 
"taskArns": [ "arn:aws:ecs:us-east-1:123456789012:task/fargate-service/EXAMPLE ] }
```

Describe the task and locate the ENI ID. Use the task ARN for the `tasks` parameter.
```
aws ecs describe-tasks --cluster fargate-cluster --tasks arn:aws:ecs:us-east-1:123456789012:task/service/EXAMPLE | grep eni
```

The attachment information is listed in the output.
```
"value": "eni-0fa40520aeEXAMPLE"
```


Describe the ENI to get the public IP address.
```
aws ec2 describe-network-interfaces --network-interface-id  eni-0fa40520aeEXAMPLE | grep PublicIp
```

Output
```
"PublicIp": "198.51.100.2"
```

Enter the public IP address in your web browser and you should see a webpage that displays the **Amazon ECS** sample application. 
Visit `http://PublicIp`
```
Amazon ECS Sample App
Congratulations!
Your application is now running on a container in Amazon ECS.
```
## Step 8: Clean Up

Delete the service.
``` 
aws ecs delete-service --cluster `fargate-cluster` --service `fargate-service` --force 
```

Delete the cluster.
```
aws ecs delete-cluster --cluster fargate-cluster
```