# Prerequisites:
- Amazon Linux 2023 AMI
- t3a.medium instance type
- 2 vCPU, 4 GB RAM, 30 GB EBS storage

# References:
- https://docs.percona.com/postgresql/17/tarball.html
- https://docs.percona.com/postgresql/17/connect.html
- https://docs.percona.com/postgresql/17/crud.html#update-data

# Notes：
>In production environment， it is recommended to use `postgres` instead of `mypguser` as the user to run the PostgreSQL server.

  
# 1. Install Percona Distribution for PostgreSQL from binary tarballs

## Use ec2-user
To check what OpenSSL version you have, run the following command:
```shell
openssl version
```

## For RHEL and derivatives, run the following command:
Create the user to own the PostgreSQL process. For example, mypguser, Run the following command:
```shell
sudo useradd mypguser -m
sudo passwd mypguser
```

```shell
sudo useradd postgres -m
sudo passwd postgres
```
## The steps below install the tarballs for OpenSSL 3.x on x86_64 architecture.

1. Create the directory where you will store the binaries. For example, /opt/pgdistro
```shell
sudo mkdir /opt/pgdistro -p
```

2. Grant access to this directory for the mypguser user.
```shell
sudo chown mypguser:mypguser /opt/pgdistro
```

```shell
sudo chown postgres:postgres /opt/pgdistro
```

3. Fetch the binary tarball.
```shell
wget https://downloads.percona.com/downloads/postgresql-distribution-17/17.2/binary/tarball/percona-postgresql-17.2-ssl3-linux-x86_64.tar.gz
```

4. Extract the tarball to the directory for binaries that you created on step 1.
```shell
sudo tar -xvf percona-postgresql-17.2-ssl3-linux-x86_64.tar.gz -C /opt/pgdistro
sudo chown mypguser:mypguser /opt/pgdistro -R
```

```shell
sudo tar -xvf percona-postgresql-17.2-ssl3-linux-x86_64.tar.gz -C /opt/pgdistro
sudo chown postgres:postgres /opt/pgdistro -R
```

5. If you extracted the tarball in a directory other than /opt, copy percona-python3, percona-tcl and percona-perl to the /opt directory. This is required for the correct run of libraries that require those modules.
```shell
sudo cp <path_to>/percona-perl <path_to>/percona-python3 <path_to>/percona-tcl /opt/
```

6. Add the location of the binaries to the PATH variable:
```shell
export PATH=:/opt/pgdistro/percona-haproxy/sbin/:/opt/pgdistro/percona-patroni/bin/:/opt/pgdistro/percona-pgbackrest/bin/:/opt/pgdistro/percona-pgbadger/:/opt/pgdistro/percona-pgbouncer/bin/:/opt/pgdistro/percona-pgpool-II/bin/:/opt/pgdistro/percona-postgresql17/bin/:/opt/pgdistro/percona-etcd/bin/:/opt/percona-perl/bin/:/opt/percona-tcl/bin/:/opt/percona-python3/bin/:$PATH
```

7. Create the data directory for PostgreSQL server. For example, /usr/local/pgsql/data.
```shell
sudo mkdir /usr/local/pgsql/data -p
```

8. Grant access to this directory for the mypguser user.
```shell
sudo chown mypguser:mypguser /usr/local/pgsql/data
```

```shell
sudo chown postgres:postgres /usr/local/pgsql/data
```
9. Switch to the user that owns the Postgres process. In our example, mypguser:
```shell
sudo su - mypguser
```

```shell
sudo su - postgres
```

10. Initiate the PostgreSQL data directory:
```shell
/opt/pgdistro/percona-postgresql17/bin/initdb -D /usr/local/pgsql/data
```

11. Start the PostgreSQL server:
```shell
/opt/pgdistro/percona-postgresql17/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start
```

12. Connect to psql
```shell
/opt/pgdistro/percona-postgresql17/bin/psql -d postgres
```
# 2. Start the components

## Use mypguser/postgres

After you unpacked the tarball and added the location of the components’ binaries to the $PATH variable, the components are available for use. You can invoke a component by running its command-line tool.

```shell
export PATH=:/opt/pgdistro/percona-haproxy/sbin/:/opt/pgdistro/percona-patroni/bin/:/opt/pgdistro/percona-pgbackrest/bin/:/opt/pgdistro/percona-pgbadger/:/opt/pgdistro/percona-pgbouncer/bin/:/opt/pgdistro/percona-pgpool-II/bin/:/opt/pgdistro/percona-postgresql17/bin/:/opt/pgdistro/percona-etcd/bin/:/opt/percona-perl/bin/:/opt/percona-tcl/bin/:/opt/percona-python3/bin/:$PATH

haproxy version
```

# 3. Connect to the PostgreSQL serve

 1. List databases:
```
$ \l
```

2. Display tables in the current database:
```
$ \dt
```

3. Display columns in a table
```
$ \d <table_name>
```

4. Switch databases
```
$ \c <database_name>
```

5. Display users and roles
```
$ \du
```

6. Exit the psql terminal:
```
$ \q
```

# 4. Manipulate data in PostgreSQL
Create a database

CREATE DATABASE <database_name>;
```sql
CREATE DATABASE test;
```

CREATE TABLE <table_name> (<column_name> <data_type>);
Let’s create a sample table Customers in the test database using the following command:

```sql
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,  -- 'id' is an auto-incrementing integer
    first_name VARCHAR(50), -- 'first_name' is a string with a maximum length of 50 characters
    last_name VARCHAR(50),  -- 'last_name' is a string with a maximum length of 50 characters
    email VARCHAR(100)      -- 'email' is a string with a maximum length of 100 characters
);
```

Insert data into the table
Populate the table with the sample data as follows:
```sql
INSERT INTO customers (first_name, last_name, email)
VALUES
    ('John', 'Doe', 'john.doe@example.com'),  -- Insert a new row
    ('Jane', 'Doe', 'jane.doe@example.com')，
    ('Alice', 'Smith', 'alice.smith@example.com');
```

Query data
```sql
SELECT * FROM customers;
```

Update data
```sql
UPDATE customers
SET email = 'john.doe@myemail.com'
WHERE first_name = 'John' AND last_name = 'Doe';
```

Query the table to verify the updated data:
```sql
SELECT * FROM customers WHERE first_name = 'John' AND last_name = 'Doe';
```

Delete data
Use the DELETE command to delete rows. For example, delete the record of Alice Smith:
```sql
DELETE FROM Customers WHERE first_name = 'Alice' AND last_name = 'Smith';
```

If you wish to delete the whole table, use the DROP TABLE command instead as follows:
```sql
DROP TABLE customers;
```

To delete the whole database, use the DROP DATABASE command:
```sql
DROP DATABASE test;
```
