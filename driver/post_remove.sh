#!/bin/bash
# Bash script to remove the old module emuc2socketcan and install the new one generated by dkms
# This script is used in the post_install.sh file of the debian package
MODULE_NAME="emuc2socketcan"
KERNEL_VERSION=$(uname -r)

if [ "$(grep -c "^${MODULE_NAME}" /proc/modules)" -ne 0 ]; then
    sudo systemctl stop emuccan
    modprobe -r ${MODULE_NAME} || true
fi

# restore backed up module if it exists
if [ -f "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko.bak" ]; then
    mv "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko.bak" "/usr/lib/modules/${KERNEL_VERSION}/extra/${MODULE_NAME}.ko"
fi

rm /etc/depmod.d/${MODULE_NAME}.conf || true
rm /etc/modules-load.d/${MODULE_NAME}.conf || true
