# References:
https://neon.tech/postgresql/postgresql-getting-started/postgresql-sample-database
https://neon.tech/postgresql/postgresql-getting-started/load-postgresql-sample-database

# 1. Install PostgreSQL

> Notes: Must use the `postgres` account 

[[AWS - EC2 - PostgreSQL - Install Percona Distribiution for PostgreSQL]]

# 2. Load and verify the sample database tar 

```shell
wget https://neon.tech/postgresqltutorial/dvdrental.zip
unzip dvdrental.zip
```

```shell
export PATH=:/opt/pgdistro/percona-haproxy/sbin/:/opt/pgdistro/percona-patroni/bin/:/opt/pgdistro/percona-pgbackrest/bin/:/opt/pgdistro/percona-pgbadger/:/opt/pgdistro/percona-pgbouncer/bin/:/opt/pgdistro/percona-pgpool-II/bin/:/opt/pgdistro/percona-postgresql17/bin/:/opt/pgdistro/percona-etcd/bin/:/opt/percona-perl/bin/:/opt/percona-tcl/bin/:/opt/percona-python3/bin/:$PATH

psql -U postgres

> CREATE DATABASE dvdrental;
> \l
> exit

```


```shell
pg_restore -U postgres -d dvdrental ./dvdrental.tar
```

```shell
psql -U postgres

>\c dvdrental
>\dt
```

```
List of relations 
 Schema | Name | Type | Owner
--------+---------------+-------+----------
 public | actor | table | postgres 
 public | address | table | postgres 
 public | category | table | postgres 
 public | city | table | postgres 
 public | country | table | postgres 
 public | customer | table | postgres 
 public | film | table | postgres 
 public | film_actor | table | postgres 
 public | film_category | table | postgres 
 public | inventory | table | postgres 
 public | language | table | postgres 
 public | payment | table | postgres 
 public | rental | table | postgres 
 public | staff | table | postgres 
 public | store | table | postgres
(15 rows)
```

## 3. pgAdmin Install 

Create a new EC2 instance, and run an ubuntu AMI
https://www.pgadmin.org/download/pgadmin-4-apt/
```
#
# Setup the repository
#

# Install the public key for the repository (if not done previously):
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

# Create the repository configuration file:
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

#
# Install pgAdmin
#

# Install for both desktop and web modes:
sudo apt install pgadmin4

# Install for desktop mode only:
sudo apt install pgadmin4-desktop

# Install for web mode only: 
sudo apt install pgadmin4-web 

# Configure the webserver, if you installed pgadmin4-web:
sudo /usr/pgadmin4/bin/setup-web.sh
```

Config the postgresql server side
```
1. configure the  listen_addresses in postgresql.conf to "*"
2. configure `host all all ip trust` in pg_hba.conf
```

Now you can connect the pgsql from the UI web tools.