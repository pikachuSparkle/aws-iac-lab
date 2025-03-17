
When managing an RDS instance, a common task is to upgrade the database to a new major version. To do so, you will upgrade the database engine version and the parameter group family in your Terraform configuration, and apply the change.
## References
https://developer.hashicorp.com/terraform/tutorials/aws/rds-upgrade#upgrade-rds-instance

## Prerequisites
[[AWS - Terraform - Tutorial - RDS - Upgrade RDS major version - 1 - Create RDS instance]]


## Take a snapshot

Before you upgrade your database, create a backup snapshot of your data. It is good practice to back up your data when you perform operations on your databases so that you have a point of recovery in the event of data loss or other error.

Add the following configuration to `main.tf` to create a snapshot of your database.

`main.tf`
```
resource "aws_db_snapshot" "pre_16_upgrade" {
  db_instance_identifier = aws_db_instance.education.identifier
  db_snapshot_identifier = "pre16upgradebackup"
}
```


Add the following to `outputs.tf` to report the identifier and status of your DB snapshot.
`outputs.tf`
```
output "rds_pre_16_backup_identifier" {
  description = "Identifier of the snapshot created before upgrading RDS instance to PostgreSQL 16."
  value = aws_db_snapshot.pre_16_upgrade.db_snapshot_identifier
}

output "rds_pre_16_backup_status" {
  description = "Status of the snapshot created before upgrading RDS instance to PostgreSQL 16."
  value = aws_db_snapshot.pre_16_upgrade.status
}
```


Apply your configuration to create the snapshot. Enter `yes` when prompted to confirm the operation.
```
terraform apply
```

## Update RDS instance version

In this Terraform configuration, the `aws_db_instance` resource references the `aws_db_parameter_group`, creating an implicit dependency between the two. As a result, Terraform would first try to upgrade the parameter group, but would error out because the destructive update would attempt to remove a parameter group associated with a running RDS instance.

Terraform offers lifecycle meta-arguments to help you manage more complex resource dependencies such as this one. In this case, the `aws_db_parameter_group` in the example configuration includes the `create_before_destroy` argument to ensure that Terraform provisions the new parameter group and upgrades your RDS instance before destroying the original parameter group.

In your `main.tf` file, make the following changes:

In the `aws_rds_parameter_group` resource definition, update the `family` argument to `postgres16` as shown below.

`main.tf` ----> `family = "postgres16"`
```
resource "aws_db_parameter_group" "education" {
  name_prefix = "${random_pet.name.id}-education"
  family      = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```
Update the `version` argument for the `aws_db_instance` resource to `16`.
`main.tf` ----> `engine_version = "16"`
```
resource "aws_db_instance" "education" {
  identifier                  = "${random_pet.name.id}-education"
  instance_class              = "db.t3.micro"
  allocated_storage           = 10
  apply_immediately           = true
  engine                      = "postgres"
  engine_version              = "16"
## ...
}
```

## Upgrade RDS instance

In your terminal, apply your configuration changes to replace the parameter group and upgrade the engine version of your RDS instance. Enter `yes` when prompted to approve the operation.

```
terraform apply
```

```
NOTES:
- Major version upgrades to RDS are a destructive change. AWS will remove the existing data from your database, and you will need to reload it.
- This upgrade may take up to 20 minutes.
```

## Verify upgrade

Verify that the RDS instance is using Postgres 16.
```shell
psql -h $(terraform output -raw rds_hostname) -U $(terraform output -raw rds_username) postgres -c "SELECT version()"
```

```shell
psql -h $(terraform output -raw rds_hostname) -U $(terraform output -raw rds_username) postgres
```

Explanation:

- **`psql`**: This is the command-line tool for interacting with PostgreSQL databases.    
- **`-h $(terraform output -raw rds_hostname)`**: Specifies the hostname of the PostgreSQL server. The hostname is retrieved from Terraform using the `terraform output` command, specifically from an output variable named `rds_hostname`. The `-raw` flag ensures that the output is not wrapped in quotes.
- **`-U $(terraform output -raw rds_username)`**: Specifies the username to use for the connection. The username is retrieved from Terraform using the `terraform output` command, specifically from an output variable named `rds_username`.
- **`postgres`**: This is the name of the database to connect to. In this case, it's the default PostgreSQL database named "postgres".
- 
## Destroy infrastructure

Once you have completed the tutorial, destroy your infrastructure to avoid incurring unnecessary costs. Type `yes` when prompted to confirm the operation.

```
terraform destroy
```
