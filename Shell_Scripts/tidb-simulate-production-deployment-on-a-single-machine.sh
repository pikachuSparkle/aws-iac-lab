# t3a.xlarge


# Download and install TiUP:
sudo -i
cd ~/
curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
# Output:
#===============================================
#Successfully set mirror to https://tiup-mirrors.pingcap.com
#Detected shell: bash
#Shell profile:  /root/.bash_profile
#/root/.bash_profile has been modified to add tiup to PATH
#open a new terminal or source /root/.bash_profile to use it
#Installed path: /root/.tiup/bin/tiup
#===============================================
#Have a try:     tiup playground
#===============================================

# Declare the global environment variable.
#after the above command, tiup is installed into /root/.tiup/bin/tiup
source /root/.bash_profile


# Install the cluster component of TiUP:
sed 's/10.0.1.1/172.31.82.56/g' -i topo.yaml


tiup cluster deploy tidb-playgroud v8.5.0  ./topo.yaml --user root -i key.pem
tiup cluster start tidb-playgroud
tiup cluster display tidb-playgroud
tiup cluster display tidb-playgroud --topology


http://184.72.207.123:2379/dashboard/


