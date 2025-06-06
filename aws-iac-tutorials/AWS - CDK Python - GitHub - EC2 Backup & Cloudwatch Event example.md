## DOCS:
https://github.com/aws-samples/aws-cdk-examples/blob/main/python/ec2-cloudwatch/README.md

## Source Obtaining

```
git clone https://github.com/aws-samples/aws-cdk-examples.git
cd aws-cdk-examples/python/ec2-cloudwatch
```

This project demonstrates how to:
- Create a new VPC with an S3 endpoint
- Create two instances - a web server and a bastion host
- Create a Cloudwatch Event rule to stop instances at UTC 15pm every day
- Create a backup vault and a backup rule to protect resources

The `cdk.json` file tells the CDK Toolkit how to execute your app.

## Setup up your environment

Manually create a virtualenv.
```
python -m venv .env
```

Activate your virtualenv.
```
.env\Scripts\activate
```

Once the virtualenv is activated, you can install the required dependencies.
```
pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.
```
cdk synth
```

Configure your aws command line context if needed.
```
pip install awscli
```

```
aws configure
```

## Refine your codes

Change your customized `instance type` and `key pair`.
```
# set up an web instance in public subnet
...
(self, "WebInstance",
 instance_type=aws_ec2.InstanceType("Write a EC2 instance type"),
 machine_image=amzn_linux,
 vpc=vpc_new,
 vpc_subnets=aws_ec2.SubnetSelection(subnet_type=aws_ec2.SubnetType.PUBLIC),
 security_group=my_security_group,
 key_name="Your SSH key pair name")
...

```

Write your own IP rang to access this bastion instead of 1.2.3.4/32
```
host_bastion.allow_ssh_access_from(aws_ec2.Peer.ipv4("1.2.3.4/32"))
```
## Deploy the stack

```
cdk synth
```

```
cdk deploy
```

## Clean the resources
```
cdk destroy
```

