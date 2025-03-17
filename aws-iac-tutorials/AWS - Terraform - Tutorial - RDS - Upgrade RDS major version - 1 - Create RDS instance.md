
Terraform enables you to manage your Amazon Relational Database Service (RDS) instances over their lifecycle. Using Terraform's built-in lifecycle arguments, you can manage the dependency and upgrade ordering for tightly coupled resources like RDS instances and their parameter groups. You will also use Terraform to securely set your database password and store it in AWS Systems Manager (SSM).

In this tutorial, you will configure an RDS instance with Terraform, storing the password in SSM. Next, you will perform a major version upgrade on your RDS instance using Terraform and review how Terraform handles dependencies when you use it to manage resources that depend on other resources in your configuration.

## References
https://developer.hashicorp.com/terraform/tutorials/aws/rds-upgrade

## Prerequisites

This tutorial assumes that you are familiar with the standard Terraform workflow. If you are new to Terraform, complete the [Get Started tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started) first.

For this tutorial, you will need:
- Terraform v1.11+ installed locally
- an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start) with credentials [configured for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
- the [AWS CLI](https://aws.amazon.com/cli/), configured with the same credentials you use for Terraform
- The [`psql`](https://www.postgresql.org/download/) command line utility for PostgreSQL
- The [`jq` utility](https://stedolan.github.io/jq/download/) installed and in your `PATH`

## Clone example repository

Clone the [example repository](https://github.com/hashicorp-education/learn-terraform-rds-upgrade) for this tutorial, which contains configuration for an RDS instance and parameter group.
```shell
git clone https://github.com/hashicorp-education/learn-terraform-rds-upgrade
```

Change into the repository directory.
```shell
cd learn-terraform-rds-upgrade
```


## Review example configuration

Open `main.tf` in your code editor to review the resources you will provision. This configuration defines the following resources:

- The provider block which configures your AWS region and default tags.
- A data source to load the availability zones for your configured region.
- An AWS VPC to provision your RDS instance in.
- An RDS subnet group, which designates a collection of subnets for RDS placement.
- A security group that will allow access to your RDS instance on port `5432`.
- An RDS parameter group.
- An `aws_db_instance`, configured with PostgreSQL 15.

```
Notes:
The example configuration allows access to your RDS instance from the public internet, so that you can connect to it later in this tutorial. **In production scenarios, we recommend you follow security best practices, such as placing your RDS instance in a private subnet and restricting access to it only from subnets you control.**

The `aws_db_parameter_group` resource's `family` attribute configures the major version of your database instance. In this case, the parameter group family is `postgres15`, so the RDS engine will be PostgreSQL v15.
```


main.tf
```
resource "aws_db_parameter_group" "education" {
  name_prefix = "${random_pet.name.id}-education"
  family      = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

While you could use a default AWS parameter group for your database, we recommend that you maintain a custom one for your RDS instances. You cannot modify the parameters on the default parameter groups maintained by AWS. If you need to update an RDS setting in the future, you can modify your custom parameter group rather than creating a new one at that time.

The configuration generates a random password for your RDS instance using an ephemeral resource. The configuration then sets this password for your database using a write-only argument. The configuration also stores and encrypts the generated password in AWS SSM using another write-only argument. for your RDS instance, and stores the password as a parameter in AWS SSM, encrypted with your default SSM key. The configuration sets the password for your database and stores it in SSM using write-only arguments.

Review the ephemeral resource for the database password in `main.tf`.

main.tf
```
ephemeral "random_password" "db_password" {
  length = 16
}
```

The `random_password.db_password` is an ephemeral resource. Terraform does not store ephemeral resources in its state or plan files.

```
Notes:
Ephemeral resources and values are available in Terraform 1.10 and later.
```


The configuration uses `random_password.db_password` to set the value of two write-only arguments. A resource's write-only arguments are only available during the current operation, and Terraform does not store the argument's values in state or plan files. Terraform providers define write-only arguments for values that you do not want to store in Terraform's state, such as passwords or other secrets.

The first write-only argument, `aws_db_instance.password_wo`, sets the password on the RDS instance. The second write-only argument, `aws_ssm_parameter.value_wo`, stores the password value as an AWS SSM secret. With this configuration, Terraform does not store your database password, and the only way to retrieve that password is by querying the AWS SSM parameter.

main.tf
```
locals {
  # Increment db_password_version to update the DB password and store the new
  # password in SSM.
  db_password_version = 1
}

resource "aws_db_instance" "education" {
  identifier                  = "${random_pet.name.id}-education"
  instance_class              = "db.t3.micro"
  allocated_storage           = 10
  apply_immediately           = true
  engine                      = "postgres"
  engine_version              = "15"
  username                    = "edu"
  password_wo                 = ephemeral.random_password.db_password.result
  password_wo_version         = local.db_password_version
## ...
}

resource "aws_ssm_parameter" "secret" {
  name             = "/education/database/password/master"
  description      = "Password for RDS database."
  type             = "SecureString"
  value_wo         = ephemeral.random_password.db_password.result
  value_wo_version = local.db_password_version
}
```

Because Terraform does not store the value of write-only arguments, it cannot detect if the value of a write-only argument changed in your configuration. To track whether a write-only argument changes, the AWS provider includes accompanying versioning arguments: `password_wo` uses `password_wo_version` and `value_wo` uses `value_wo_version`.

Versioning arguments are tracked in state. You can indicate to Terraform and providers that a write-only arguments has changed by incrementing the corresponding `_version` argument. For example, incrementing `password_wo_version` lets Terraform know the value of `password_wo` has changed. Terraform then records that change in its plan, notifying the provider that `password_wo` has a new value it can use.

The example configuration sets both `password_wo_version` and `value_wo_version` to the same local value, `local.db_password_version`. If the values were hard-coded, a user might update one of these values but not the other, and cause the database password to become out of sync with the password stored in SSM.

```
Notes:
Write-only arguments are available in Terraform 1.11 and later.
```

## Create RDS instance

Change proper region for your aws account in `variables.tf`
```
variable "region" {
  description = "AWS region for all resources."
  default     = "us-east-1"
```

In your terminal, initialize the Terraform configuration to install the module and providers used in this tutorial.
```
terraform init
```

Next, apply your configuration to create your RDS instance and other resources. Enter `yes` when prompted to confirm the operation. Note that it can take up to 10 minutes to create an RDS instance.

```
terraform apply
```

Notice that the RDS hostname, port, and username are marked as sensitive. The example configuration sets the `sensitive` attribute to `true` for these outputs so that Terraform won't include those values in its output by default. For example, the `rds_hostname` output block is designated as sensitive.

outputs.tf
```
output "rds_hostname" {
  description = "RDS instance hostname."
  value       = aws_db_instance.education.address
  sensitive   = true
}
```

Unlike ephemeral resources and write-only arguments, Terraform stores sensitive values in its state file, and will output these values as plain text if you specify the `-raw` flag for the `terraform output` command, or the `-json` flag to print out your workspace's output values in JSON format. Terraform stores sensitive values unencrypted in its state file, so you must keep this file secure.

## Seed database with mock data

Next, connect to the database with the `psql` command line utility, and seed it. The `coffees.sql` file in the repository contains commands that populate your database with mock data about HashiCorp-themed coffee beverages.

`psql` can access your password using thr `PGPASSWORD` environment variable. Set your PostgreSQL password as an environment variable by retrieving the parameter from AWS SSM and using `jq` to extract the password from the response.


```shell
export PGPASSWORD=$( \
  aws ssm get-parameter \
    --region=$(terraform output -raw region) \
    --name=/education/database/password/master \
    --with-decryption \
  | jq --raw-output '.Parameter.Value' \
  )
```

```
Notes:
The previous command will save your database password unencrypted in the `PGPASSWORD` environment variable in your shell session. For production use cases, you may wish to unset this value once you are done using it.
```

Then, execute the script.

```shell
psql -h $(terraform output -raw rds_hostname) -U $(terraform output -raw rds_username) postgres -f coffees.sql
```

Connect to your database to inspect your records.

```shell
psql -h $(terraform output -raw rds_hostname) -U $(terraform output -raw rds_username) postgres

psql (16.3, server 15.5)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, compression: off)
Type "help" for help.

postgres=>
```

At the postgres prompt, list all of the coffees in your database.

```sql
SELECT * FROM coffees;    
```

Type `exit` to exit psql.