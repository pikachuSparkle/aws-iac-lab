## Prerequisites

This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates)

There are two methods that you could obtain the demo codes:
1. From the AWS templates GitHub: [AutoScaling/AutoScalingRollingUpdates.yaml](https://github.com/aws-cloudformation/aws-cloudformation-templates/blob/main/AutoScaling/AutoScalingRollingUpdates.yaml)
```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/AutoScaling/
ll ./AutoScalingRollingUpdates.yaml
```
2. From this repo
```
./CloudFormation_Codes/AutoScalingRollingUpdates.yaml
```

NOTES:
As of **January 1, 2023**, new instance types are no longer supported in launch configurations.
Migrating your Auto Scaling groups to launch templates is needed. [Issue Resolved](https://github.com/aws-cloudformation/aws-cloudformation-templates/pull/481)

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-autoscaling-launchconfiguration.html
Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. For more information, see Launch configurations in the Amazon EC2 Auto Scaling User Guide.

## Description:

This example creates an auto scaling group behind a load balancer with a simple health check. The Auto Scaling launch configuration includes an update policy that will keep 2 instances running while doing an autoscaling rolling update. The update will roll forward only when the ELB health check detects an updated instance in-service. 

## Resources

Resource References source website:
- [EC2 Launch Template](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-launchtemplate.html)
- [Auto Scaling Group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-autoscaling-autoscalinggroup.html)

EC2 Launch Template
- **Type**: `AWS::EC2::LaunchTemplate`.
- **Properties**:
    - **LaunchTemplateData**:
        - **KeyName**: Uses the specified key pair.    
        - **ImageId**: Finds the appropriate AMI based on region and instance type architecture.   
        - **InstanceType**: Uses the specified instance type.    
        - **SecurityGroups**: References the instance security group.   
        - **IamInstanceProfile**: Uses the web server instance profile.  
        - **UserData**: Installs necessary packages and configures the instance.  

Auto Scaling Group - WebServerGroup
- **Type**: `AWS::AutoScaling::AutoScalingGroup`.
- **Properties**:
    - **AvailabilityZones**: Uses all available zones in the region.
    - **LaunchTemplate**: References a launch template with the latest version.
    - **MinSize**: 2 instances.
    - **MaxSize**: 4 instances.
    - **LoadBalancerNames**: References the Elastic Load Balancer.
    - **UpdatePolicy**: Enables rolling updates with a batch size of 1, ensuring at least 1 instance is in service during updates.   

Elastic Load Balancer
- **Type**: `AWS::ElasticLoadBalancing::LoadBalancer`.
- **Properties**:
    - **AvailabilityZones**: Uses all available zones.
    - **CrossZone**: Enabled for cross-zone load balancing.
    - **Listeners**: Listens on port 80 for HTTP traffic.
    - **HealthCheck**: Checks instance health by querying HTTP on port 80.

Security Group and IAM Role
- **InstanceSecurityGroup**: Allows SSH and HTTP traffic.
- **WebServerInstanceProfile**: Includes a role that allows describing instance health for ELB.

## Outputs

**URL**: Provides the URL of the website hosted behind the ELB.
You can visit the output URL after CloudFormation stack provisioned. and validate the result.

## Explanation of Key Concepts

- **Auto Scaling Rolling Updates**: This feature allows you to update instances in an Auto Scaling group by replacing them one by one, ensuring that at least a minimum number of instances are in service during the update process. The update pauses until the ELB health check confirms that the updated instance is in service.

```
 WebServerGroup:
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M
        Count: 2
```

NOTES:
`Count: 2` means that at least 2 instance's signals are needed. Hence, at least 2 EC2 instances should be provisioned (`MinSize: 2`).

- **Launch Template**: A launch template is used to define the configuration for instances launched by Auto Scaling. It includes details like instance type, AMI, security groups, and user data scripts.

- **Elastic Load Balancer (ELB)**: An ELB distributes incoming traffic across instances in the Auto Scaling group, ensuring that no single instance is overwhelmed. It also performs health checks to ensure only healthy instances receive traffic.

## Update the stack

Updating an AWS CloudFormation stack involves modifying the existing template or parameters and then applying those changes to the stack. Here's a step-by-step guide on how to update a stack (Update Stack via AWS Management Console):

1. **Log in to the AWS Management Console**:
    - Navigate to the [CloudFormation console](https://console.aws.amazon.com/cloudformation).
        
2. **Select the Stack**:
    - Choose the stack you want to update from the list of stacks.
        
3. **Update Stack**:
    - In the stack details pane, click **Update**.
        
4. **Specify Template**:
    - If you have modified the template, select **Replace current template**.
    - Choose how you want to provide the updated template:
        - **Upload a template file**: Select a file from your local machine.
        - **Amazon S3 URL**: Enter the URL of the template stored in S3.
    - Click **Next**.
        
5. **Specify Stack Details**:
    - Review or update any stack parameters as needed.
    - Click **Next**.
        
6. **Configure Stack Options**:
    - Review or update any stack options (e.g., tags, IAM roles).
    - Click **Next**.
        
7. **Review**:
    - Verify all changes are correct.
    - Click **Update stack** to apply the changes.

Check and Validate you stack in CloudFormation and EC2 dashboard, you will observing the rolling update results.  