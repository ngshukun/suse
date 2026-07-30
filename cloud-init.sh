#cloud-config
preserve_hostname: false
fqdn: suse

# Create the user and give sudo
users:
  - default
  - name: suse
    groups: [wheel]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

# Set password (plaintext) – not recommended for production
ssh_pwauth: true
chpasswd:
  expire: false
  users:
    - name: suse
      password: "suse/4u"   # quotes avoid any YAML surprises
      type: text

# sshd is usually enabled already, but harmless:
runcmd:
  - systemctl enable --now sshd

# for ubuntu
#cloud-config
# Create the user and give sudo
users:
  - name: suse
    groups: [wheel, adm, sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false

# Set password (plaintext) – not recommended for production
ssh_pwauth: true
chpasswd:
  expire: false
  users:
    - name: suse
      password: "suse/4u"   # quotes avoid any YAML surprises
      type: text

# sshd is usually enabled already, but harmless:
runcmd:
  - systemctl enable --now sshd
  - systemctl enable --now ssh
  - [ systemctl, restart, ssh]
  - [ systemctl, restart, sshd]