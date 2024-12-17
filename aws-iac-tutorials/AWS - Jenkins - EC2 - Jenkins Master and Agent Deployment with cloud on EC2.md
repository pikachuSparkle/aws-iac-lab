
Jenkins is an open-source automation server that integrates with a number of AWS Services, including: AWS CodeCommit, AWS CodeDeploy, Amazon EC2 Spot, and Amazon EC2 Fleet. You can use Amazon Elastic Compute Cloud (Amazon EC2) to deploy a Jenkins application on AWS.

This tutorial walks you through the process of deploying a Jenkins application. You will launch an EC2 instance, install Jenkins on that instance, and configure Jenkins to automatically spin up Jenkins agents if build abilities need to be augmented on the instance.

references: 
https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/#jenkins-on-aws
## 1. Prerequisites
- Disk size 40G+
- OS amazon2023
- 2G2C+

## 2. EC2 Instance Preparation
#### Creating a key pair

#### Creating a security group

#### Launching an Amazon EC2 instance

## 3. Installing and configuring Jenkins

#### Installing Jenkins

Ensure that your software packages are up to date on your instance by using the following command to perform a quick software update:
```
[ec2-user ~]$ sudo yum update –y
```

Add the Jenkins repo using the following command:
```
[ec2-user ~]$ sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
```

Import a key file from Jenkins-CI to enable installation from the package:
```
[ec2-user ~]$ sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
```

```
[ec2-user ~]$ sudo yum upgrade
```

Install Java (Amazon Linux 2023):
```
[ec2-user ~]$ sudo dnf install java-17-amazon-corretto -y
```

Install Jenkins:
```
[ec2-user ~]$ sudo yum install jenkins -y
```

Enable the Jenkins service to start at boot:
```
[ec2-user ~]$ sudo systemctl enable jenkins
```

Start Jenkins as a service:
```
[ec2-user ~]$ sudo systemctl start jenkins
```

You can check the status of the Jenkins service using the command:
```
[ec2-user ~]$ sudo systemctl status jenkins
```

#### Configuring Jenkins

Jenkins is now installed and running on your EC2 instance. To configure Jenkins:
1. Connect to http://<your_server_public_DNS>:8080 from your browser. You will be able to access Jenkins through its management interface:
```
#---------------------------------------------------
Getting Started
  Unlock Jenkins
  ************************************
  ************************************
#---------------------------------------------------
```
2. As prompted, enter the password found in **/var/lib/jenkins/secrets/initialAdminPassword**.
```
# Use the following command to display this password:        
[ec2-user ~]$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
3. The Jenkins installation script directs you to the **Customize Jenkins page**. Click **Install suggested plugins**.
4. Once the installation is complete, the **Create First Admin User** will open. Enter your information, and then select **Save and Continue**.
5. On the left-hand side, select **Manage Jenkins**, and then select **Manage Plugins**.
6. Select the **Available** tab, and then enter **Amazon EC2 plugin** at the top right.
7. Select the checkbox next to **Amazon EC2 plugin**, and then select **Install without restart**.
8. Once the installation is done, select **Back to Dashboard**.
9. Select **Configure a cloud** if there are no existing nodes or clouds.
10. If you already have other nodes or clouds set up, select **Manage Jenkins**.
- After navigating to **Manage Jenkins**, select **Configure Nodes and Clouds** from the left hand side of the page.
- From here, select **Clouds**.
11. Select **Add a new cloud**, and select **Amazon EC2**. A collection of new fields appears.
12. Click **Add** under Amazon EC2 Credentials
- From the Jenkins Credentials Provider, select AWS Credentials as the `Kind`.
- Scroll down and enter in the IAM User programmatic access keys with permissions (`Access Key ID` and `Secret Access Key`) to launch EC2 instances and select **Add**.
- Scroll down to select your `region` using the drop-down, and select **Add** for the `EC2 Key Pair’s Private Key`.
- From the Jenkins Credentials Provider, select `SSH Username with private key` as the `Kind` and set the Username to `ec2-user`.
- Scroll down and select `Enter Directly` under Private Key, then select **Add**.
- Open the private key pair you created in the [creating a key pair](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/#creating-a-key-pair) step and paste in the contents from "-----BEGIN RSA PRIVATE KEY-----" to "-----END RSA PRIVATE KEY-----". Select `Add` when completed.
- Scroll down to "Test Connection" and ensure it states "Success". Select **Save** when done
13. You are now ready to use EC2 instances as Jenkins agents.

## 4. Troubleshooting

#### 4.1 Built-In Node "Free Swap Space" problem
https://serverfault.com/questions/798817/jenkins-on-docker-free-swap-space-0
```
# Configure a swap file on your host
sudo dd if=/dev/zero of=swapfile bs=1M count=1K
sudo mkswap swapfile
sudo chown root:root swapfile
sudo chmod 600 swapfile
sudo swapon swapfile
```

#### 4.2 Built-In Node "Free Temp Space" problem
```
# Configure Monitors
```

#### 4.3 AMIs in Cloud Configuration
ADD Configuration in "Cloud" "AMIs"
```
AMI ID: ami-01816d07b1128cd2d
Instance Type: T3aMicro
Remote user: ec2-user
Init script:
sudo dnf install java-17-amazon-corretto -y
```

NOTES: 
- The "Jenkins agent" instances will be launched in "us-east-1" "default VPC" "default security group"
- Guarantee "Jenkins master" will be launched will "Jenkins agent" in one subnet

## 5. Validate

Create a pipeline -> running a "Hello World" demo

## 6. Deleting your EC2 instance
1. In the left-hand navigation bar of the Amazon EC2 console, select **Instances**.
2. Right-click on the instance you created earlier, and select **Terminate**.