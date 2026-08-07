# to install k9s
kubectl get secret -n cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'{{"\n"}}

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

