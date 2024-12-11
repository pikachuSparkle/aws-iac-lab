## 0. References:
https://www.postgresql.org/download/
https://www.server-world.info/en/note?f=5&os=Ubuntu_24.04&p=postgresql

## 1. Install & start PostgreSQL Server on all nodes

To manually configure the Apt repository, follow these steps:
```
# Import the repository signing key:
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update the package lists:
sudo apt update

# Install the latest version of PostgreSQL:
# If you want a specific version, use 'postgresql-16' or similar instead of 'postgresql'
sudo apt -y install postgresql
```


The repository contains many different packages including third party addons. The most common and important packages are (substitute the version number as required):

| postgresql-client-16     | client libraries and client binaries                      |
| ------------------------ | --------------------------------------------------------- |
| postgresql-16            | core database server                                      |
| postgresql-doc-16        | documentation                                             |
| libpq-dev                | libraries and headers for C language frontend development |
| postgresql-server-dev-16 | libraries and headers for C language backend development  |
## 2. Configure Primary Node

Change the postgresql.conf an follows:
```
vi /etc/postgresql/16/main/postgresql.conf
```

```
# line 60 : uncomment and change  
listen_addresses = '*'

# line 211 : uncomment
wal_level = replica

# line 216 : uncomment
synchronous_commit = on

# line 314 : uncomment (max number of concurrent connections from streaming clients)
max_wal_senders = 10

# line 328 : uncomment and change 
synchronous_standby_names = '*'
```

Change the pg_hba.conf an follows:
```
vi /etc/postgresql/16/main/pg_hba.conf
```

We need change the allowed network to our hosts ip
```
# add to last line  
# host replication [replication user] [allowed network] [authentication method]
host    replication     rep_user        10.0.0.30/32            scram-sha-256
host    replication     rep_user        10.0.0.51/32            scram-sha-256
```

```
# create a user for replication
su - postgres
createuser --replication -P rep_user 
Enter password for new role:    
Enter it again:

exit

systemctl restart postgresql
```

## 3. Configure Standby Node

```
# stop PostgreSQL and remove existing data
systemctl stop postgresql
rm -rf /var/lib/postgresql/16/main/*
```

```
# get backup from Primary Node
su - postgres
pg_basebackup -R -h primary-ip -U rep_user -D /var/lib/postgresql/16/main -P
Password:   # input password of replication user
30799/30799 kB (100%), 1/1 tablespace  
exit
```

```
vi /etc/postgresql/16/main/postgresql.conf
```

```
# line 60 : uncomment and change  
listen_addresses = '*'

# line 339 : uncomment
hot_standby = on
```

```
systemctl start postgresql
```


## 4. Validate

That's OK if result of the command below on Primary Node is like follows. Verify the setting works normally to create databases or to insert data on Primary Node.

```
psql -c "select usename, application_name, client_addr, state, sync_priority, sync_state from pg_stat_replication;"

 usename  |application_name | client_addr |   state   | sync_priority|sync_state
----------+-----------------+-------------+-----------+--------------+---------
 rep_user | 16/main         | 10.0.0.51   | streaming |            1 | sync
```


```
# on the primary server
SELECT * FROM pg_stat_replication;

# on the standby server
SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();

```

create tables & insert sample date
```
CREATE TABLE person (
  id SERIAL PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  age INT CHECK (age >= 0 AND age <= 120)
);
```

```
DO $$
BEGIN
  FOR i IN 1..100 LOOP
    INSERT INTO person (first_name, last_name, email, age)
    VALUES (
      'First_' || i,
      'Last_' || i,
      'person_' || i || '@example.com',
      floor(random() * 100)
    );
  END LOOP;
END $$;
```

```
# Remember to commit your changes after inserting the data:
COMMIT;

```

```
SELECT * FROM person;
```
