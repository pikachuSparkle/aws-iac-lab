
## SSM - Check available AMIs

command:
```
aws ssm get-parameters-by-path --path /aws/service/ami-amazon-linux-latest --query "Parameters[].Name"
```

output:
```
[
    "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-6.1-arm64",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-6.1-x86_64",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-s3",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-minimal-hvm-x86_64-s3",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-minimal-pv-x86_64-s3",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-pv-x86_64-s3",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-arm64-gp2",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs",
    "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-minimal-hvm-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-minimal-pv-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/amzn-ami-pv-x86_64-ebs",
    "/aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs"
]
```

## SSM - Check Specified AMI  

command:
```
aws ssm get-parameter --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64" --query "Parameter.Value" --output text
```
output:
```
ami-0df8c184d5f6ae949
```

## Check AMI Info

command:
```
aws ec2 describe-images --image-ids ami-5f709f34
```

output:
```
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2015-06-04T08:12:16.000Z",
            "ImageId": "ami-5f709f34",
            "ImageLocation": "amazon/ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20150603",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "099720109477",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0822c746",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                },
                {
                    "DeviceName": "/dev/sdb",
                    "VirtualName": "ephemeral0"
                },
                {
                    "DeviceName": "/dev/sdc",
                    "VirtualName": "ephemeral1"
                }
            ],
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20150603",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "DeprecationTime": "2022-08-28T23:59:59.000Z"
        }
    ]
}

```

command:
```
aws ec2 describe-images --image-ids ami-0075013580f6322a1 --region us-west-2
```

output:
```
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2024-07-01T16:36:59.000Z",
            "ImageId": "ami-0075013580f6322a1",
            "ImageLocation": "amazon/ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240701",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "099720109477",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0e5588bd53af1ff2c",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                },
                {
                    "DeviceName": "/dev/sdb",
                    "VirtualName": "ephemeral0"
                },
                {
                    "DeviceName": "/dev/sdc",
                    "VirtualName": "ephemeral1"
                }
            ],
            "Description": "Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2024-07-01",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240701",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "BootMode": "uefi-preferred",
            "DeprecationTime": "2026-07-01T16:36:59.000Z"
        }
    ]
}
```

## Find Specified AMI in different region

#### Find version  according to AMI ID & region

```
aws ec2 describe-images --image-ids ami-02f624c08a83ca16f --region us-east-1
```

```
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2025-03-21T23:44:07.000Z",
            "ImageId": "ami-02f624c08a83ca16f",
            "ImageLocation": "amazon/amzn2-ami-kernel-5.10-hvm-2.0.20250321.0-x86_64-gp2",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "137112412989",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0cc602f2182e094de",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                }
            ],
            "Description": "Amazon Linux 2 Kernel 5.10 AMI 2.0.20250321.0 x86_64 HVM gp2",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "amzn2-ami-kernel-5.10-hvm-2.0.20250321.0-x86_64-gp2",
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "DeprecationTime": "2025-07-01T00:00:00.000Z"
        }
    ]
}
```


#### Find AMI ID according to version & region

```
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0.20250321.0-x86_64-gp2" --region us-east-1
```

```
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2025-03-21T23:44:07.000Z",
            "ImageId": "ami-02f624c08a83ca16f",
            "ImageLocation": "amazon/amzn2-ami-kernel-5.10-hvm-2.0.20250321.0-x86_64-gp2",
            "ImageType": "machine",
            "Public": true,
            "OwnerId": "137112412989",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0cc602f2182e094de",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                }
            ],
            "Description": "Amazon Linux 2 Kernel 5.10 AMI 2.0.20250321.0 x86_64 HVM gp2",
            "EnaSupport": true,
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "amzn2-ami-kernel-5.10-hvm-2.0.20250321.0-x86_64-gp2",
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "VirtualizationType": "hvm",
            "DeprecationTime": "2025-07-01T00:00:00.000Z"
        }
    ]
}
```

