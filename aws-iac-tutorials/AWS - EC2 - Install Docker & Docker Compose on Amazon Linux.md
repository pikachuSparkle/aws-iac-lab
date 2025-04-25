## Prerequisites

- Amazon Linux 2023
- Amazon Linux 2

## Install Docker

```shell
sudo dnf install docker
sudo systemctl start docker.service
sudo systemctl enable docker.service
```

## Install Docker Compose

Docker Compose 1.28 or later

```shell
# https://docs.docker.com/compose/install/linux/#install-the-plugin-manually
DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
sudo mkdir -p $DOCKER_CONFIG/cli-plugins
```

```shell
sudo curl -SL https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
```

```shell
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

```shell
sudo docker compose version
```

NOTES:
If the `$DOCKER_CONFIG` environment variable is not set, the script will use the default value `/usr/local/lib/docker`. 
