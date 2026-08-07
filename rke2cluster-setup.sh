# to find out the secret for rancher prime check for the secret in cattle-system, bootstrap-secret
kubectl get secret -n cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'{{"\n"}}'

# download rke2 script 
# sudo as root

curl -sfL http://get.rke2.io -o ./install.sh