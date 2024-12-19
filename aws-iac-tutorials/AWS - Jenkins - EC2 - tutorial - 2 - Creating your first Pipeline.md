## 0. References
https://www.jenkins.io/doc/pipeline/tour/hello-world/#creating-your-first-pipeline

>Jenkins Pipeline (or simply "Pipeline") is a suite of plugins which supports implementing and integrating _continuous delivery pipelines_ into Jenkins.

>A _continuous delivery pipeline_ is an automated expression of your process for getting software from version control right through to your users and customers.

>Jenkins Pipeline provides an extensible set of tools for modeling simple-to-complex delivery pipelines "as code". The definition of a Jenkins Pipeline is typically written into a text file (called a `Jenkinsfile`) which in turn is checked into a project’s source control repository. 

>For more information about Pipeline and what a `Jenkinsfile` is, refer to the respective [Pipeline](https://www.jenkins.io/doc/book/pipeline) and [Using a Jenkinsfile](https://www.jenkins.io/doc/book/pipeline/jenkinsfile) sections of the User Handbook.

## 1. Prerequisites

- Jenkins installed on a EC2 Amazon2023 instances, at least have a `Build-in Node` -- [[AWS - Jenkins - EC2 - tutorial - 1 - Jenkins Master and Agent Deployment with cloud on EC2]]
```shell
sudo wget -O /etc/yum.repos.d/jenkins.repo  https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo dnf install java-17-amazon-corretto -y
sudo yum install jenkins -y
sudo systemctl start jenkins.service
sudo systemctl enable jenkins.service
# resolve the agent disk monitoring problems as tutorial - 1
```
- Docker installed in master and agents
```shell
sudo dnf install docker -y
sudo systemctl start docker.service
sudo systemctl status docker.service
```
- Docker privileges configured for username `jenkins`, to invoke docker service
```shell
# this command needs logout and login to take effect
# here, try restart the Jenkins application
sudo usermod -aG docker jenkins 
less /etc/group  | grep jenkins
less /etc/passwd | grep jenkins
sudo systemctl stop jenkins.service
sudo systemctl start jenkins.service
```

## 2. Get started quickly with Pipeline

1. Install the [**Docker Pipeline plugin**](https://plugins.jenkins.io/docker-workflow/) through the **Manage Jenkins > Plugins** page
2. After installing the plugin, restart Jenkins so that the plugin is ready to use
3. 1. Copy one of the [examples below](https://www.jenkins.io/doc/pipeline/tour/hello-world/#examples) into your repository and name it `Jenkinsfile`
4. Click the **New Item** menu within Jenkins
5. Provide a name for your new item (e.g. **My-Pipeline**) and select **Pipeline**
6. Scroll to the bottom "Pipeline script", copy the following example
```groovy
/* Requires the Docker Pipeline plugin */
pipeline {
    agent { docker { image 'maven:3.9.9-eclipse-temurin-21-alpine' } }
    stages {
        stage('build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}
```
7. Click the **Save** button and watch your first Pipeline run

## 3. Validate
Check the Console Output
```
...
...
...
...
+ mvn --version
Apache Maven 3.9.9 (8e8579a9e76f7d015ee5ec7bfcdc97d260186937)
Maven home: /usr/share/maven
Java version: 21.0.5, vendor: Eclipse Adoptium, runtime: /opt/java/openjdk
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "6.1.119-129.201.amzn2023.x86_64", arch: "amd64", family: "unix"
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
$ docker stop --time=1 799f2e9f55d7bd79ef5d938b4efc7fccfb250a5e8b3d7118c0fc3bdc8b92be95
$ docker rm -f --volumes 799f2e9f55d7bd79ef5d938b4efc7fccfb250a5e8b3d7118c0fc3bdc8b92be95
[Pipeline] // withDockerContainer
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```