
根据Rancher的documentation，可以通过terraform在AWS上面自动化部署K3S+Rancher+K8S集群

1、创建2个`t3a.medium`就可以（`t3a.medium`比`t3.medium`便宜10%）
2、windows不需要创建，其ami编号可以选择一个能返回的就行

## References：

https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/aws

## Processes

1. Clone [Rancher Quickstart](https://github.com/rancher/quickstart) to a folder using
```
git clone https://github.com/rancher/quickstart
```

2. Go into the AWS folder containing the Terraform files by executing
```
cd quickstart/rancher/aws
```

3. 1. Rename the `terraform.tfvars.example` file to `terraform.tfvars`.

4. 1. Edit `terraform.tfvars` and customize the following variables:
    
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

## Result

Two Kubernetes clusters are deployed into your AWS account, one running Rancher Server and the other ready for experimentation deployments. Please note that while this setup is a great way to explore Rancher functionality, a production setup should follow our high availability setup guidelines. SSH keys for the VMs are auto-generated and stored in the module directory.
