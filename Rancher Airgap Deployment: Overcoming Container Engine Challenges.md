# Rancher Airgap Deployment: Overcoming Container Engine Challenges

Setting up Rancher in an airgapped environment presents unique challenges, particularly regarding the underlying container engine. The official automation scripts behave differently depending on whether native Docker or Podman is executing the commands. 

## Environment Baseline

Because SUSE Linux Enterprise Server (SLES) Micro installs Podman by default and aliases it to the `docker` command, it is critical to verify the actual engine running on the workstation.

The following are the detail of the OS used:

**Container Engine & OS Specifications**

```sh
node01:~ # docker version
docker version 5.4.2

node01:~ # podman version
Client:       Podman Engine
Version:      5.4.2
API Version:  5.4.2
Go Version:   go1.24.6
Built:        Wed Aug 13 06:44:07 2025
OS/Arch:      linux/amd64

node01:~ # cat /etc/*release*
NAME="SLES"
PRETTY_NAME="SUSE Linux Enterprise Server 16.0"
VARIANT="Micro"
VARIANT_ID="transactional"
VERSION="16.0"
SUSE_PRETTY_NAME="SUSE Linux Micro 6.2"
```

# The 28MB Archive Mystery

To prepare the airgapped payload, three files were downloaded from the Rancher GitHub releases page (`rancher-images.txt`, `rancher-save-images.sh`, and `rancher-load-images.sh`). After making the save script executable, it was triggered to package the required images:  

```sh
chmod +x rancher-save-images.sh
./rancher-save-images.sh --image-list ./rancher-images.txt
```

The following output observed:

```sh
-rw-r--r--. 1 root root  21631 Aug 27 16:33 rancher-2.14.1.tgz
-rw-r--r--. 1 root root 28804221 Aug 28 04:25 rancher-images.tar.gz
-rw-r--r--. 1 root root  32737 Aug 27 13:17 rancher-images.txt
-rwxr-xr-x. 1 root root   4095 Aug 27 13:17 rancher-load-images.sh
-rwxr-xr-x. 1 root root   1747 Aug 27 13:17 rancher-save-images.sh
```

A significant discrepancy occurred upon completion. Despite docker system df reporting 697 images consuming 119.7GB of local cache, the resulting rancher-images.tar.gz file was mathematically impossible at only ~28MB.

# Cache Verification Output 

```sh
node01:~/rancher-v2.14.1-airgap # docker system df
TYPE     TOTAL   ACTIVE   SIZE    RECLAIMABLE
Images    697    0     119.7GB  119.7GB (100%)
Containers  0     0     0B     0B (0%)
Local Volumes 0     0     0B     0B (0%)

node01:~/rancher-v2.14.1-airgap # docker images | grep rancher/rancher
registry.suse.com/rancher/rancher                         v2.14.1                           df77b9db07a2 3 months ago 1.89 GB
```

**The root cause stems from CLI differences:**
* The official `rancher-save-images.sh` script is explicitly written for native Docker.  
* When Docker receives a command to save multiple images simultaneously, it streams them into a single, unified archive.  
* Podman processes that same list sequentially, repeatedly overwriting the output file.  
* The 28MB file was not compressed; it was simply the very last container image on the list.  

## The Podman Workaround

To force Podman to combine the 119.7GB of cached images into a single payload, the official script must be bypassed using Podman's built-in `--multi-image-archive` (`-m`) flag. 

walkaround:

```sh
docker images --format '{{.Repository}}:{{.Tag}}' | grep 'registry.suse.com/rancher' > valid-local-images.txt
podman save -m -o rancher-images-full.tar $(cat valid-local-images.txt)
gzip rancher-images-full.tar
```

with the final result:

```sh
-rw-r--r--. 1 root root       21631 Aug 27 16:33 rancher-2.14.1.tgz
-rw-r--r--. 1 root root 44364755441 Aug 28 09:12 rancher-images-full.tar.gz
-rw-r--r--. 1 root root       32737 Aug 27 13:17 rancher-images.txt
-rwxr-xr-x. 1 root root        4095 Aug 27 13:17 rancher-load-images.sh
-rwxr-xr-x. 1 root root        1747 Aug 27 13:17 rancher-save-images.sh
-rw-r--r--. 1 root root       45283 Aug 28 08:39 valid-local-images.txt
```

This manual workaround successfully generated the correct rancher-images-full.tar.gz file at roughly 44.3GB.

# Container Engine Comparison
Choosing the right container runtime impacts different phases of the Rancher lifecycle:

* Architecture: Docker relies on a heavy background daemon (dockerd) running as root, whereas Podman is daemonless and can run rootless, spinning up containers as direct child processes of the user.

* Ecosystem Compatibility: Docker remains the industry standard for universal script compatibility. Podman acts as a secure, drop-in replacement by Red Hat, but minor CLI differences can break complex shell scripts.

* Airgap Preparation: Native Docker is highly preferred for the local workstation downloading the files, as Rancher’s official automation scripts are tested exclusively against Docker's specific behavior.

* Kubernetes Cluster (RKE2): Modern Kubernetes distributions like RKE2 completely bypass both Docker and Podman. RKE2 runs on containerd, a lightweight, deeply integrated container runtime designed strictly for machine-to-machine communication.