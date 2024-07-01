#!/bin/bash
# Bash script to remove the old module emuc2socketcan and install the new one generated by dkms
# This script is used in the post_install.sh file of the debian package
MODULE_NAME="emuc2socketcan"
KERNEL_VERSION=$(uname -r)

if [ "$(grep -c "^${MODULE_NAME}" /proc/modules)" -ne 0 ]; then
    sudo systemctl stop emuccan || true
    modprobe -r ${MODULE_NAME} || true
fi

# find the old manually installed module and backup it
if [ -f "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko" ]; then
    mv "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko" "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko.bak"
fi

# https://man7.org/linux/man-pages/man5/depmod.d.5.html
sudo tee /etc/depmod.d/${MODULE_NAME}.conf <<EOF
# Ensure the new module is loaded
override ${MODULE_NAME} * updates/dkms/
EOF

echo "${MODULE_NAME}" | sudo tee /etc/modules-load.d/${MODULE_NAME}.conf

depmod -a

modprobe ${MODULE_NAME} || true
