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