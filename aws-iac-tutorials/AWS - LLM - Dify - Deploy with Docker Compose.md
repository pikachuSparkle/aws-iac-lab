
## DOCS
https://docs.dify.ai/getting-started/install-self-hosted/docker-compose

## Prerequisites

Before installing Dify, make sure your machine meets the following minimum system requirements:
- CPU >= 2 Core, RAM >= 4 GiB
- OS: Amazon Linux 2023
- Docker 19.03 or later 

## Install Docker & Docker Compose

[[AWS - EC2 - Install Docker & Docker Compose on Amazon Linux]]

## Clone Dify

```shell
sudo dnf install git
```

```shell
# Assuming current latest version is 0.15.3
git clone https://github.com/langgenius/dify.git --branch 0.15.3
```

## Starting Dify

Navigate to the Docker directory in the Dify source code
```
cd dify/docker
```

Copy the environment configuration file
```
cp .env.example .env
```

Start the Docker containers

Choose the appropriate command to start the containers based on the Docker Compose version on your system. You can use the $ docker compose version command to check the version, and refer to the Docker documentation for more information:

If you have Docker Compose V2, use the following command:

```shell
sudo docker compose up -d
```


After executing the command, you should see output similar to the following, showing the status and port mappings of all containers:
```
[+] Running 11/11
 ✔ Network docker_ssrf_proxy_network  Created              0.1s 
 ✔ Network docker_default             Created              0.0s 
 ✔ Container docker-redis-1           Started              2.4s 
 ✔ Container docker-ssrf_proxy-1      Started              2.8s 
 ✔ Container docker-sandbox-1         Started              2.7s 
 ✔ Container docker-web-1             Started              2.7s 
 ✔ Container docker-weaviate-1        Started              2.4s 
 ✔ Container docker-db-1              Started              2.7s 
 ✔ Container docker-api-1             Started              6.5s 
 ✔ Container docker-worker-1          Started              6.4s 
 ✔ Container docker-nginx-1           Started              7.1s
```


 Finally, check if all containers are running successfully:

```shell
sudo docker compose ps
```


This includes 3 core services: api / worker / web, and 6 dependent components: weaviate / db / redis / nginx / ssrf_proxy / sandbox .

```
NAME                  IMAGE                              
docker-api-1          langgenius/dify-api:0.6.13      
docker-db-1           postgres:15-alpine                 
docker-nginx-1        nginx:latest                       
docker-redis-1        redis:6-alpine                    
docker-sandbox-1      langgenius/dify-sandbox:0.2.1    
docker-ssrf_proxy-1   ubuntu/squid:latest                
docker-weaviate-1     semitechnologies/weaviate:1.19.0      
docker-web-1          langgenius/dify-web:0.6.13         
docker-worker-1       langgenius/dify-api:0.6.13        
```
With these steps, you should be able to install Dify successfully.

## Upgrade Dify

Enter the docker directory of the dify source code and execute the following commands:
```
cd dify/docker
docker compose down
git pull origin main
docker compose pull
docker compose up -d
```

## Sync Environment Variable Configuration (Important)

- If the `.env.example` file has been updated, be sure to modify your local `.env` file accordingly.
- Check and modify the configuration items in the `.env` file as needed to ensure they match your actual environment. You may need to add any new variables from `.env.example` to your `.env` file, and update any values that have changed.


## Access Dify

Access administrator initialization page to set up the admin account:
```shell
# Server environment
http://your_server_ip/install
```

Dify web interface address:
```shell
# Server environment
http://your_server_ip
```

## Customize Dify
Edit the environment variable values in your `.env` file directly. Then, restart Dify with:
```
docker compose down
docker compose up -d
```
The full set of annotated environment variables along can be found under docker/.env.example.