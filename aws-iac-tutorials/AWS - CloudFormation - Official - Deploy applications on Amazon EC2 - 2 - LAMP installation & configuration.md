This article follows the AWS CloudFormation Documentation [Deploy applications on Amazon EC2](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/deploying.applications.html)
You can get the source code from
```
./CloudFormation_Codes/Deploy_applications_on_Amazon_EC2_2.yaml
```

>NOTES:
>This demo can only be run on the specific AMI, even though the AMI amazon Linux 2018 is out of date. Because the package installation command and packages have been changed a lot, in nowadays  modern amazon Linux 2023.

## LAMP installation

We'll build on the previous basic Amazon EC2 template - [[AWS - CloudFormation - Official - Deploy applications on Amazon EC2 - 1 - Basic Amazon EC2 instance]] - to automatically install Apache, MySQL, and PHP. To install the applications, we'll add a `UserData` property and `Metadata` property. However, the template won't configure and start the applications until the next section.

The `UserData` property runs two shell commands: 
- install the CloudFormation helper scripts 
- then run the [cfn-init](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html) helper script. 
Because the helper scripts are updated periodically, running the `yum install -y aws-cfn-bootstrap` command ensures that you get the latest helper scripts. 
When you run cfn-init, it reads metadata from the [AWS::CloudFormation::Init](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html) resource, which describes the actions to be carried out by cfn-init. For example, you can use cfn-init and `AWS::CloudFormation::Init` to install packages, write files to disk, or start a service. In this case, cfn-init installs the listed packages (httpd, mysql, and php) and creates the `/var/www/html/index.php` file (a sample PHP application).

## LAMP configuration

Now that we have a template that installs Linux, Apache, MySQL, and PHP, we'll need to expand the template so that it automatically configures and runs Apache, MySQL, and PHP. In the following example, we expand on the `Parameters` section, `AWS::CloudFormation::Init` resource, and `UserData` property to complete the configuration. As with the previous template, sections marked with an ellipsis (...) are omitted for brevity. Additions to the template are shown in red italic text.

The example defines the `DBUsername` and `DBPassword` parameters with their `NoEcho` property set to `true`. If you set the `NoEcho` attribute to `true`, CloudFormation returns the parameter value masked as asterisks (*****) for any calls that describe the stack or stack events, except for information stored in the locations specified below.

The example adds more parameters to obtain information for configuring the MySQL database, such as the database name, user name, password, and root password. The parameters also contain constraints that catch incorrectly formatted values before CloudFormation creates the stack.

In the `AWS::CloudFormation::Init` resource, we added a MySQL setup file, containing the database name, user name, and password. The example also adds a `services` property to ensure that the `httpd` and `mysqld` services are running (`ensureRunning` set to `true`) and to ensure that the services are restarted if the instance is rebooted (`enabled` set to `true`). A good practice is to also include the [cfn-hup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-hup.html) helper script, with which you can make configuration updates to running instances by updating the stack template. For example, you could change the sample PHP application and then run a stack update to deploy the change.

In order to run the MySQL commands after the installation is complete, the example adds another configuration set to run the commands. Configuration sets are useful when you have a series of tasks that must be completed in a specific order. The example first runs the `Install` configuration set and then the `Configure` configuration set. The `Configure` configuration set specifies the database root password and then creates a database. In the commands section, the commands are processed in alphabetical order by name, so the example adds a number before each command name to indicate its desired run order.


## CreationPolicy attribute

Finally, you need a way to instruct CloudFormation to complete stack creation only after all the services (such as Apache and MySQL) are running and not after all the stack resources are created. In other words, if you use the template from the earlier section to launch a stack, CloudFormation sets the status of the stack as `CREATE_COMPLETE` after it successfully creates all the resources. However, if one or more services failed to start, CloudFormation still sets the stack status as `CREATE_COMPLETE`. To prevent the status from changing to `CREATE_COMPLETE` until all the services have successfully started, you can add a [CreationPolicy attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html) attribute to the instance. This attribute puts the instance's status in `CREATE_IN_PROGRESS` until CloudFormation receives the required number of success signals or the timeout period is exceeded, so you can control when the instance has been successfully created.

The following example adds a creation policy to the Amazon EC2 instance to ensure that cfn-init completes the LAMP installation and configuration before the stack creation is completed. In conjunction with the creation policy, the example needs to run the [cfn-signal](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html) helper script to signal CloudFormation when all the applications are installed and configured.

The creation policy attribute uses the ISO 8601 format to define a timeout period of 5 minutes. And because you're waiting for 1 instance to be configured, you only need to wait for one success signal, which is the default count.

In the `UserData` property, the template runs the cfn-signal script to send a success signal with an exit code if all the services are configured and started successfully. When you use the cfn-signal script, you must include the stack ID or name and the logical ID of the resource that you want to signal. If the configuration fails, cfn-signal sends a failure signal that causes the resource creation to fail. The resource creation also fails if CloudFormation doesn't receive a success signal within the timeout period.

The following example shows the final complete template.

You can also view the template at the following location: [LAMP_Single_Instance.template](https://s3.amazonaws.com/cloudformation-templates-us-east-1/LAMP_Single_Instance.template) for the us-east-1 AWS Region or 
```
./CloudFormation_Codes/Deploy_applications_on_Amazon_EC2_2.yaml
```
