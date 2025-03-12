
## Prerequisites:

According to Rancher's [DOCS](https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/aws)，you can automate the deployment of K3S -> Rancher -> K8S cluster on AWS using Terraform.

- You only need to create 2 `t3a.medium` instances (the `t3a.medium` is 10% cheaper than the `t3.medium`).
- There is no need to create a Windows instance; you can choose any AMI ID that returns successfully.

## Installation Processes

1. Clone [Rancher Quickstart](https://github.com/rancher/quickstart) to a folder using
```
git clone https://github.com/rancher/quickstart
```

2. Go into the AWS folder containing the Terraform files by executing
```
cd quickstart/rancher/aws
```

3. Rename the `terraform.tfvars.example` file to `terraform.tfvars`.

4. Edit `terraform.tfvars` and customize the following variables:
    
    - `aws_access_key` - Amazon AWS Access Key
    - `aws_secret_key` - Amazon AWS Secret Key
    - `rancher_server_admin_password` - Admin password for created Rancher server. See [Setting up the Bootstrap Password](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/resources/bootstrap-password#password-requirements) for password requirments.

5. **Optional:** Modify optional variables within `terraform.tfvars`. See the [Quickstart Readme](https://github.com/rancher/quickstart) and the [AWS Quickstart Readme](https://github.com/rancher/quickstart/tree/master/rancher/aws) for more information. Suggestions include:
    
    - `aws_region` - Amazon AWS region, choose the closest instead of the default (`us-east-1`)
    - `prefix` - Prefix for all created resources
    - `instance_type` - EC2 instance size used, minimum is `t3a.medium` but `t3a.large` or `t3a.xlarge` could be used if within budget
    - `add_windows_node` - If true, an additional Windows worker node is added to the workload cluster

6. Run `terraform init`.
7. To initiate the creation of the environment, run `terraform apply --auto-approve`. Then wait for output similar to the following:
```
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.  
  
Outputs:  
  
rancher_node_ip = xx.xx.xx.xx  
rancher_server_url = https://rancher.xx.xx.xx.xx.sslip.io  
workload_node_ip = yy.yy.yy.yy
```

8. Paste the `rancher_server_url` from the output above into the browser. Log in when prompted (default username is `admin`, use the password set in `rancher_server_admin_password`).

9. ssh to the Rancher Server using the `id_rsa` key generated in `quickstart/rancher/aws`.

## Validate

Two Kubernetes clusters are deployed into your AWS account, one running Rancher Server and the other ready for experimentation deployments. Please note that while this setup is a great way to explore Rancher functionality, a production setup should follow our high availability setup guidelines. SSH keys for the VMs are auto-generated and stored in the module directory.
