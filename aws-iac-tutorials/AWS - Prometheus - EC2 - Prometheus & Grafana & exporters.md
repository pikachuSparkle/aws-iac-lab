## 0. Prerequisites:

- Ubuntu 24.04
- 2C4G20G EC2 Instance for Prometheus
- 2C4G20G EC2 Instance for Grafana
- Version:
	- Choose the newest version: prometheus-3.0.1.linux-amd64.tar.gz
	- Choose the newest version: grafana-enterprise-10.4.2.linux-amd64.tar.gz
	- Choose the newest version: node_exporter-1.8.2.linux-amd64.tar.gz
	- Choose the newest version: mysqld_exporter-0.16.0.linux-amd64.tar.gz

## 1. docs:
https://prometheus.io/docs/prometheus/latest/installation/
https://prometheus.io/docs/visualization/grafana/
download urls for prometheus & exporters
https://prometheus.io/download/
download url for grafana
https://grafana.com/grafana/download

## 2. Prometheus server installation with precompiled binaries

installation process
```shell
wget \ https://github.com/prometheus/prometheus/releases/download/v3.0.1/prometheus-3.0.1.linux-amd64.tar.gz

tar xvzf prometheus-3.0.1.linux-amd64.tar.gz

cd prometheus

./prometheus --config.file=prometheus.yml & 

# after closing the terminal, the program keep running
# visit the service with http://Public-IP:9090
```

prometheus.yml
```
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["IP:9090"]

  - job_name: 'nodes'
    static_configs:
      - targets: ['IP-1:4444', 'IP-2:4444','IP-3:4444','IP-4:4444']

  - job_name: 'mysqls'
    static_configs:
      - targets: ['IP:9104']
```

## 3. Grafana installation with precompiled binaries
```shell
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-11.4.0.linux-amd64.tar.gz

tar -zxvf grafana-enterprise-11.4.0.linux-amd64.tar.gz

cd grafana-v11.4.0/bin/

./grafana-server &

# ---------------------------------------------------------
# visit service url IP:3000
# default username & password  admin & admin

# change password
#$ ./grafana-cli admin reset-admin-password yourpassword
# ---------------------------------------------------------
```

add data source from grafana UI

## 4. node_exportor install

```shell
tar xvzf node_exporter-1.8.2.linux-amd64.tar.gz

cd node_exportor

nohup /data/node_exporter-1.8.2.linux-amd64/node_exporter --web.listen-address="0.0.0.0:4444" &

# for keep running after end the termenal session

```

## 5. mysqld_exportor install

```
tar xvzf mysqld_exporter-0.16.0.linux-amd64.tar.gz

cd  mysqld_exportor

nohup ./mysqld_exporter --config.my-cnf=./mysqld_exporter.cnf  &

```

mysqld_exportor.cnf
```
[client]
user=root
password=yourpassword
host=x.x.x.x  # exportor host ip
```

