# Setting up rancher cluster from rke2 cluster using manual cert
# ca-chain.crt, server,crt and server.key was created and place in /home/suse 
# create a namespace called cattle-system
kubectl create ns cattle-system
# Create the ingress TLS secret
kubectl -n cattle-system create secret tls tls-rancher-ingress \
  --cert=/home/suse/server.crt \
  --key=/home/suse/server.key

# Create the CA secret (using tls.crt as the CA certificate for self-signed)
kubectl -n cattle-system create secret generic tls-ca \
  --from-file=cacerts.pem=/home/suse/ca-chain.crt
  
# Run the following commands on your internet-connected machine to pull the v2.13.8 scripts and image lists directly from the SUSE Prime repository:

export VERSION="v2.13.8"
export RIBS_URL="https://prime.ribs.rancher.io/rancher/${VERSION}"

# Download image list and packaging scripts
curl -L -O "${RIBS_URL}/rancher-images.txt"
curl -L -O "${RIBS_URL}/rancher-save-images.sh"
curl -L -O "${RIBS_URL}/rancher-load-images.sh"

chmod +x rancher-save-images.sh rancher-load-images.sh

# Fetch the exact v2.13.8 Helm chart archive from the Rancher Prime enterprise chart repository:

helm repo add rancher-prime https://charts.rancher.com/server-charts/prime
helm repo update
helm pull rancher-prime/rancher --version 2.13.8

# you will need to download container images from internet connected env the following are from sk account. from the terminal, perform following:
podman login registry.rancher.com -u c1c862f821
password: a749bba8e9

# Download the container images
./rancher-save-images.sh \
--image-list ./rancher-images.txt \
--source-registry registry.rancher.com