It can be challenging when trying to sett up rancher in airgapped environment, this section will cover all the challenges i encountered during the setup of rancher cluster.
the use of container engine is particular critical, as one of the challenges encountered is due to the different behavior podman and docker when runnning the save image command.

The following are the detail of the OS used:

```sh
docker version 5.4.2 ## <--- important to take note
podman version
Client:       Podman Engine
Version:      5.4.2
API Version:  5.4.2
Go Version:   go1.24.6
Built:        Wed Aug 13 06:44:07 2025
OS/Arch:      linux/amd64

# OS used for rancher setup
NAME="SLES"
PRETTY_NAME="SUSE Linux Enterprise Server 16.0"
VARIANT="Micro"
VARIANT_ID="transactional"
VERSION="16.0"
VERSION_ID="16.0"
ANSI_COLOR="0;32"
ID="sles"
ID_LIKE="suse opensuse sle-micro sl-micro microos opensuse-microos"
CPE_NAME="cpe:/o:suse:sles:16:16.0"
SUSE_SUPPORT_PRODUCT="SUSE Linux Micro"
SUSE_SUPPORT_PRODUCT_VERSION="6.2"
SUSE_PRETTY_NAME="SUSE Linux Micro 6.2"

```

Podman is install by default if you using SUSE Linux Enterprise Server micro.
The use of container engine is critical when you need to download massive container images from registry.suse.com to the terminal.
I will detailed the exact steps performed for clarity.
In the example below, 3 content were downloaded from the following link from a internet conected environment:

```sh
https://github.com/rancher/rancher/releases
rancher-images.txt
rancher-save-images.sh
rancher-load-images.sh
```

Set rancher-save-images.sh an executable:

```sh
chmod +x rancher-save-images.sh
```

Ran rancher-save-images.sh with the rancher-images.txt image list to create a tarball of all the required images:

```sh
./rancher-save-images.sh --image-list ./rancher-images.txt
```

The following output is observed:

```sh
-rw-r--r--. 1 root root  21631 Aug 27 16:33 rancher-2.14.1.tgz
-rw-r--r--. 1 root root 28804221 Aug 28 04:25 rancher-images.tar.gz
-rw-r--r--. 1 root root  32737 Aug 27 13:17 rancher-images.txt
-rwxr-xr-x. 1 root root   4095 Aug 27 13:17 rancher-load-images.sh
-rwxr-xr-x. 1 root root   1747 Aug 27 13:17 rancher-save-images.sh
```

Checked docker size and confirm there are 698 images in total adding up to almost 120 GB
one of the image is already 1.89GB,  so the tar ball size does not make senses. 

```sh
node01:~/rancher-v2.14.1-airgap # docker system df
TYPE     TOTAL   ACTIVE   SIZE    RECLAIMABLE
Images    697    0     119.7GB  119.7GB (100%)
Containers  0     0     0B     0B (0%)
Local Volumes 0     0     0B     0B (0%)

node01:~/rancher-v2.14.1-airgap # docker images | grep rancher/rancher
registry.suse.com/rancher/rancher                         v2.14.1                           df77b9db07a2 3 months ago 1.89 GB
```

The 28MB Archive Mystery

The official rancher-save-images.sh script was written explicitly for native Docker. When the script executes its final command to save all 697 images at once, native Docker bundles them all into a single, massive streaming archive.

Podman, however, handles this command differently. When handed a list of multiple images to save without special flags, Podman processes them sequentially and repeatedly overwrites the output file. Instead of a 44GB file containing 697 images, you ended up with a 28MB file containing only the very last image on the list. Passing the --multi-image-archive (-m) flag to Podman is the only way to force it to combine them, which the Rancher script does not do natively.

walkaround:
bypass the script and use Podman's built-in --multi-image-archive (-m) flag to force it to combine the 119 GB of cached images into a single file.

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

Docker vs. Podman

Architecture: Docker relies on a heavy background daemon (dockerd) running as root to manage containers. Podman is daemonless and can easily run rootless, spinning up containers as direct child processes of the user.

Ecosystem: Docker is the industry standard with universal script compatibility. Podman was built by Red Hat as a drop-in, secure replacement, but as you experienced, complex shell scripts often expose minor CLI differences.

Which is Preferred for Rancher?

For Airgap Preparation (Your Local Machine): Native Docker is highly preferred. Rancher’s official automation scripts are tested exclusively against Docker's specific behavior. Using Podman requires manually editing scripts or running custom workarounds (like the podman save -m command you used).

For the Kubernetes Cluster (RKE2): Neither. Modern Kubernetes distributions like RKE2 completely bypass both Docker and Podman. RKE2 runs on containerd, a lightweight, deeply integrated container runtime designed strictly for machine-to-machine communication rather than human CLI interaction.

at the end of the say, it depends on what customer preffered, and how can we perform walkaround to resolve ths issue.