# to install k9s
kubectl get secret -n cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'{{"\n"}}

# to install autocomplete for kubectl command
zypper download bash-completion
sudo rpm -ivh bash-completion*.rpm
sudo mkdir -p /etc/bash_completion.d/ 
/var/lib/rancher/rke2/bin/kubectl completion bash | sudo \ tee /etc/bash_completion.d/kubectl > /dev/null
cat <<'EOF' >> ~/.bashrc

# Load system bash completion framework
[ -f /usr/share/bash-completion/bash-completion ] && . /usr/share/bash-completion/bash-completion

# Load static kubectl completion file
[ -f /etc/bash_completion.d/kubectl ] && source /etc/bash_completion.d/kubectl

# Setup 'k' alias with completion
alias k=kubectl
complete -o default -F __start_kubectl k
EOF

exec bash

# to find out the secret for rancher prime check for the secret in cattle-system, bootstrap-secret
kubectl get secret -n cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'{{"\n"}}



# download rke2 script
# sudo as root

curl -sfL http://get.rke2.io -o ./install.sh
chmod +x install.sh
INSTALL_RKE2_CHANNEL="<<rke version. example: v1.33>>" \ INSTALL_RKE2_TYPE="<<server/agent>>" ./install.sh
mkdir -p /etc/rancher/rke2
vi /etc/rancher/rke2/config.yaml
# update the following into config file
# to find out the token, ssh into the server node as root, go to /var/lib/rancher/rke2/server/node-token  to check for the 
server: https://192.168.64.12:9345
token: K10e415da04c32af979d2858228994dc976b3fd5e244fe6a0b809f420d59dc703fb::server:kubeadmincourse

# to see cluster info
kubectl cluster-info
# to pipe cluster info to a file
mkdir -p rke2-info # create a folder so contain the dump info
kubectl cluster-info dump --output-directory="absolute path" > rke2-cluster.json

# to install rke2
curl -sfL https://get.rke2.io -o install.sh
chmod +x install.sh
INSTALL_RKE2_TYPE=server INSTALL_RKE2_CHANNEL=v1.34 ./install # <-- this will install the rke2 runtime

mkdir -p /etc/rancher/rke2
vi /etc/rancher/rke2/config.yaml # <-- you will update the config from here, such as the token, tls-san
### config.yaml ###
server: https://cluster01.example.com:9345. # <-- for server node1, no need to put, for node 2 and 3 onward, need to add this server line
token: myrke2cluster01
tls-san:                         # <-- for agent node you do no need this line
  - cluster01.example.com.       # <-- for agent node you do no need this line
cni: canal                       # <-- for agent node you do no need this line



# to uninstall rke2, from root
systemctl stop rke2-server
rke2-killall.sh
rke2-uninstall.sh
# it will remove all from the node

# airgapped installation
mkdir /root/rke2-artifacts && cd /root/rke2-artifacts/
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2-images.linux-amd64.tar.zst
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2.linux-amd64.tar.gz
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/sha256sum-amd64.txt
curl -sfL https://get.rke2.io --output install.sh
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh


# if you had a cert to put in rke2
sudo mkdir -p /var/lib/rancher/rke2/server/tls/

# Copy your custom cert and key with these EXACT filenames:
sudo cp /path/to/your/custom.crt /var/lib/rancher/rke2/server/tls/serving-kube-apiserver.crt
sudo cp /path/to/your/custom.key /var/lib/rancher/rke2/server/tls/serving-kube-apiserver.key