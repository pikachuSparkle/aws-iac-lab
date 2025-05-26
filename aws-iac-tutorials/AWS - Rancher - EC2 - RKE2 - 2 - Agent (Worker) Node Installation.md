

## Prerequisites：
- AWS EC2 instances 2c4g, abit more Disk size
- Security group, open TCP port 1-65535 
- Ubuntu22.04
NOTES:
- 前提https://docs.rke2.io/install/requirements，尤其是网络部分，我打开了私网IP内的 0-65535 TCP，一定提前打开，要不然不行
- 注意如果部署失败，一定要使用新的虚拟机，要不然报错 密码错误（使用脚本卸载`https://docs.rke2.io/install/uninstall` 也不行）

## Installation the Agent ( Worker ) Node

#### 1. Run the installer
`curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -`

#### 2. Enable the rke2-agent service
`systemctl enable rke2-agent.service`

#### 3. Configure the rke2-agent service
`mkdir -p /etc/rancher/rke2/`
`vim /etc/rancher/rke2/config.yaml`
```
server: https://<server>:9345    #写master的ip或者主机名
token: <token from server node>  #从master的/var/lib/rancher/rke2/server/node-token取
```

#### 4. Start the service
`systemctl start rke2-agent.service`
**Follow the logs, if you like**
`journalctl -u rke2-agent -f`



## NOTES：如果安装失败，必须建一个新机器安装
