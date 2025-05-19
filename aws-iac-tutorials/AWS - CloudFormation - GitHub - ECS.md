## DOCS

https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/ECS/README.md

## SOURCE Obtian - Fully Public Container

Obtain the source code from AWS GitHub
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/ECS/EC2LaunchType/
ll ./clusters/public-vpc.yaml
ll ./services/public-service.yaml
```

Obtain the source code from [pikachuSparkle](https://github.com/pikachuSparkle) GitHub
```
https://github.com/pikachuSparkle/aws-iac-lab.git
cd ./aws-iac-lab/CloudFormation_Codes/ECS/
ll ./clusters/public-vpc.yaml
ll ./services/public-service.yaml
```

Apply the above template in AWS CloudFormation dashboard 

## Architeccture

This architecture deploys your container into its own VPC, inside a public facing network subnet. The containers are hosted with direct access to the internet, and they are also accessible to other clients on the internet via a public facing application load balancer.

![[public-task-public-loadbalancer.svg]]

## Run in AWS Fargate

1. Launch the `fully public` (`public-vpc.yaml`) or the `public + private` cluster template
2. Launch the `public facing service template` (`public-service.yaml`).

NOTES:
For the parameter `StackName` in `public-service.yaml`, you should use the stack name created in `public-vpc.yaml`, whose resources will imported by the  `public-service.yaml` stack.
