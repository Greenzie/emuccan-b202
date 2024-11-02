#!/bin/bash

PROJECT_DIR=${2:-$PWD}
DRIVER_CODE_DIR=${1:-"$PROJECT_DIR/driver"}

# Define module name and version based on dkms.conf
MODULE_NAME=$(grep '^PACKAGE_NAME' "$DRIVER_CODE_DIR/dkms.conf" | awk -F'=' '{print $2}' | tr -d ' ')
VERSION=$(grep '^PACKAGE_VERSION' "$DRIVER_CODE_DIR/dkms.conf" | awk -F'=' '{print $2}' | tr -d ' ')

if [ -z "$MODULE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Error: Module name or version not found in dkms.conf"
    exit 1
fi

# Check if dkms is installed, install if missing
if ! command -v dkms &> /dev/null; then
    echo "dkms command not found. Installing dkms..."
    sudo apt update && sudo apt install -y dkms
fi

# Check if debhelper is installed, install if missing
if ! dpkg-query -W -f='${Status}' debhelper 2>/dev/null | grep -q "install ok installed"; then
    echo "debhelper not found. Installing debhelper..."
    sudo apt install -y debhelper
fi

# Check for kernel headers and install if missing
# Check for specific linux-headers-generic version and install if missing
if ! dpkg-query -W -f='${Status}' linux-headers-generic 2>/dev/null | grep -q "install ok installed"; then
    echo "Installing linux-headers-generic"
    sudo apt update
    sudo apt install -y "linux-headers-generic"
else
    echo "Required linux-headers-generic version $REQUIRED_VERSION is already installed."
fi

echo "Module: '$MODULE_NAME' | Version: '$VERSION'"

# Ensure the module directory exists in /usr/src
WORKSPACE="/usr/src/${MODULE_NAME}-${VERSION}"
sudo rm -rf "$WORKSPACE"  # Remove if it exists
sudo mkdir -p $WORKSPACE
sudo cp -r "$DRIVER_CODE_DIR"/* "$WORKSPACE"


# Step 1: Add the module
if dkms status -m "$MODULE_NAME" -v "$VERSION" | grep -q "$VERSION"; then
    echo "Module '$MODULE_NAME' already exists"
else
    sudo dkms add -m "$MODULE_NAME" -v "$VERSION"
fi

# Check if only one kernel headers are available
LINUX_HEADERS=$(ls /usr/src/ | grep 'linux-headers-')
if [ "$(echo "$LINUX_HEADERS" | wc -l)" -gt 1 ]; then
    echo "Multiple kernel headers found. Please specify the version to use."
    echo "Found kernel headers:"
    echo "$LINUX_HEADERS"
    if [ -z "$DKMS_KERNEL_SOURCE_DIR" ]; then
        echo "WARNING: DKMS_KERNEL_SOURCE_DIR is not set."
        echo "\tSet the DKMS_KERNEL_SOURCE_DIR environment variable to the desired kernel headers directory."
        echo "\tTrying to use the first kernel headers directory: $LINUX_HEADERS"
        DKMS_KERNEL_SOURCE_DIR="/usr/src/$(echo "$LINUX_HEADERS" | tail -n 1)"
    fi 
    echo "Using kernel headers from: $DKMS_KERNEL_SOURCE_DIR"
else
    echo "Single kernel headers found."
    # get the only kernel headers directory
    DKMS_KERNEL_SOURCE_DIR=$(ls -d /usr/src/linux-headers-*)
    export DKMS_KERNEL_SOURCE_DIR
    echo "Using kernel headers from: $DKMS_KERNEL_SOURCE_DIR"
fi

set -e
# Step 2: Build the module
# sudo dkms build -m "$MODULE_NAME" -v "$VERSION" --kernelsourcedir="$DKMS_KERNEL_SOURCE_DIR"
# Step 3: Create Debian package
sudo dkms mkdeb -m "$MODULE_NAME" -v "$VERSION" --kernelsourcedir="$DKMS_KERNEL_SOURCE_DIR"
set +e

# Step 4 (Optional): Create artifact package
SRC_DIR="/var/lib/dkms/${MODULE_NAME}/${VERSION}/deb/"
DST_DIR="$PROJECT_DIR/artifacts"
FILENAME="alldebs.tar"
if [ -d "$SRC_DIR" ]; then
    rm -rf "$DST_DIR" || true
    sudo mkdir -p "$DST_DIR"
    cp -r "$SRC_DIR"/*.deb "$DST_DIR"
    tar -cf "${DST_DIR}/${FILENAME}" -C "$DST_DIR" .
    echo "Artifact created at ${DST_DIR}/${FILENAME}"
else
    echo "Source directory $SRC_DIR does not exist; skipping artifact creation."
fi

# Define paths for the unpack and repack process
DEB_FILE=$(find "$DST_DIR" -name "*.deb" | head -n 1)
UNPACK_DIR="unpacked_deb"

rm -rf "$UNPACK_DIR/" || true

# Step 5: Unpack the .deb package
if [ -f "$DEB_FILE" ]; then
    echo "Unpacking $DEB_FILE for modification..."
    mkdir -p "$UNPACK_DIR"
    dpkg-deb -R "$DEB_FILE" "$UNPACK_DIR"
else
    echo "Error: .deb file not found in $DST_DIR."
    exit 1
fi

# Step 6: Add files to the unpacked package
# Create necessary directories in unpacked package
mkdir -p "$UNPACK_DIR/lib/systemd/system"
mkdir -p "$UNPACK_DIR/lib/udev/rules.d"
mkdir -p "$UNPACK_DIR/etc/modules-load.d"
mkdir -p "$UNPACK_DIR/etc/default"

set -e

# Copy files into the unpacked structure
ls "$PROJECT_DIR"
cp "$PROJECT_DIR/emuccan.service" "$UNPACK_DIR/lib/systemd/system/emuccan.service"
cp "$PROJECT_DIR/emuccan.udev" "$UNPACK_DIR/lib/udev/rules.d/60-emuccan.rules"
cp "$PROJECT_DIR/emuccan.conf" "$UNPACK_DIR/etc/modules-load.d/emuccan.conf"
cp "$PROJECT_DIR/emuccan.default" "$UNPACK_DIR/etc/default/emuccan"

rm -rf "$UNPACK_DIR/usr/src/${MODULE_NAME}-${VERSION}/debian"

# Step 7: Rebuild the .deb package with the added files
echo "Repacking the modified .deb package..."
dpkg-deb -b "$UNPACK_DIR" "$DST_DIR/modified_${MODULE_NAME}_${VERSION}.deb"

# Step 8: Clean up
rm -rf "$UNPACK_DIR"
echo "Repackaging complete. Modified package located at $DST_DIR/modified_${MODULE_NAME}_${VERSION}.deb"
