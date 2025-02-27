# Prerequisites:

- Amazon Linux 2023 (RedHat 9.5)
- t3a.medium
- docker

# Percona Server Installation

https://docs.percona.com/percona-server/8.4/docker.html

```shell
sudo dnf install docker
```

```shell
sudo chown -R 1001:1001 /root/mysql  # Percona容器默认使用uid 1001运行
sudo chmod 755 /root/mysql
```

```shell
sudo docker run -d   --name ps5   -e MYSQL_ROOT_PASSWORD=root    \  
-v /root/mysql:/var/lib/mysql -p 3306:3306   percona/percona-server:8.4
```

```shell
sudo docker logs ps5  --follow
sudo docker exec -it ps5   /bin/bash
```

```shell
sudo dnf install mariadb105
```

```shell
sudo docker exec -it ps5 mysql -uroot -proot
# or
mysql -uroot -p -h 127.0.0.1
```

# Sample DB Importation

https://dev.mysql.com/doc/employee/en/employees-installation.html

```shell
git clone https://github.com/datacharmer/test_db.git
```

To import the data into your MySQL instance, load the data through the mysql command-line tool:
```shell
mysql -uroot -p -h 127.0.0.1 -t < employees.sql
```

You can validate the Employee data using two methods, `md5` and `sha`. Two SQL scripts are provided for this purpose, `test_employees_sha.sql` and `test_employees_md5.sql`. To run the tests, use mysql:
```shell
time mysql -uroot -p -h 127.0.0.1 -t < test_employees_sha.sql

time mysql -uroot -p -h 127.0.0.1 -t < test_employees_md5.sql
```

