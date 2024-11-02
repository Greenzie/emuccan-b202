#!/bin/bash
set -e

PROJECT_DIR=${2:-$PWD}
DRIVER_CODE_DIR=${1:-"$PROJECT_DIR/driver"}

echo "==> Project directory: $PROJECT_DIR"
echo "==> Driver code directory: $DRIVER_CODE_DIR"

echo "==> Checking for the module name and version in $DRIVER_CODE_DIR/dkms.conf"
# Define module name and version based on dkms.conf
MODULE_NAME=$(grep '^PACKAGE_NAME' "$DRIVER_CODE_DIR/dkms.conf" | awk -F'=' '{print $2}' | tr -d ' ')
VERSION=$(grep '^PACKAGE_VERSION' "$DRIVER_CODE_DIR/dkms.conf" | awk -F'=' '{print $2}' | tr -d ' ')

if [ -z "$MODULE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Error: Module name or version not found in dkms.conf"
    exit 1
fi

echo "==> Module name: $MODULE_NAME"
echo "==> Version: $VERSION"

echo "==> Checking for required tools and dependencies..."
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

echo "==> Preparing to use dkms to package the module..."
# Ensure the module directory exists in /usr/src
WORKSPACE="/usr/src/${MODULE_NAME}-${VERSION}"
sudo rm -rf "$WORKSPACE"  # Remove if it exists
sudo mkdir -p $WORKSPACE
sudo cp -r "$DRIVER_CODE_DIR"/* "$WORKSPACE"


# Add the module
if dkms status -m "$MODULE_NAME" -v "$VERSION" | grep -q "$VERSION"; then
    echo "Module '$MODULE_NAME' already exists"
else
    sudo dkms add -m "$MODULE_NAME" -v "$VERSION"
fi

# Create Debian package
sudo dkms mkdeb -m "$MODULE_NAME" -v "$VERSION" --kernelsourcedir="$DKMS_KERNEL_SOURCE_DIR"


#(Optional): Create artifact package
SRC_DIR="/var/lib/dkms/${MODULE_NAME}/${VERSION}/deb/"
DST_DIR="$PROJECT_DIR/artifacts"
FILENAME="alldebs.tar"
if [ -d "$SRC_DIR" ]; then
    rm -rf "$DST_DIR" || true
    sudo mkdir -p "$DST_DIR"
    cp -r "$SRC_DIR"/*.deb "$DST_DIR"
else
    echo "==> ERROR: Source directory $SRC_DIR does not exist; skipping artifact creation."
    exit 1
fi

echo "==> Ok, now we will modify the .deb package to include additional files."
echo "==> We are doing this because we have not found a way to include additional files in the dkms package."
echo "==> This is a workaround to include the systemd service file, udev rules, and other configuration files."

echo "==> First, we will unpack the .deb package"
# Define paths for the unpack and repack process
DEB_FILE=$(find "$DST_DIR" -name "*.deb" | head -n 1)
UNPACK_DIR="unpacked_deb"

rm -rf "$UNPACK_DIR/" || true

echo "==> We have found the .deb package at $DEB_FILE"
# Unpack the .deb package
if [ -f "$DEB_FILE" ]; then
    echo "==> Unpacking $DEB_FILE for modification..."
    mkdir -p "$UNPACK_DIR"
    dpkg-deb -R "$DEB_FILE" "$UNPACK_DIR"
else
    echo "ERROR: .deb file not found in $DST_DIR."
    exit 1
fi

echo "==> We have unpacked the .deb package to $UNPACK_DIR"
echo "==> Before adding files, the unpacked package structure is as follows:"
ls "$UNPACK_DIR"
echo "==> Now we will add the necessary files to the unpacked package."

# Create necessary directories in unpacked package
mkdir -p "$UNPACK_DIR/lib/systemd/system"
mkdir -p "$UNPACK_DIR/lib/udev/rules.d"
mkdir -p "$UNPACK_DIR/etc/modules-load.d"
mkdir -p "$UNPACK_DIR/etc/default"

# Copy files into the unpacked structure
ls "$PROJECT_DIR"
cp "$PROJECT_DIR/emuccan.service" "$UNPACK_DIR/lib/systemd/system/emuccan.service"
cp "$PROJECT_DIR/emuccan.udev" "$UNPACK_DIR/lib/udev/rules.d/60-emuccan.rules"
cp "$PROJECT_DIR/emuccan.conf" "$UNPACK_DIR/etc/modules-load.d/emuccan.conf"
cp "$PROJECT_DIR/emuccan.default" "$UNPACK_DIR/etc/default/emuccan"

echo "==> We added the files to the unpacked package."
rm -rf "$UNPACK_DIR/usr/src/${MODULE_NAME}-${VERSION}/debian"
echo "==> After adding files, the unpacked package structure is as follows:"
ls "$UNPACK_DIR"


# Rebuild the .deb package with the added files
echo "==> Now we will rebuild the .deb package with the added files."
echo "==> Repacking the modified .deb package..."
dpkg-deb -b "$UNPACK_DIR" "$DST_DIR/modified_${MODULE_NAME}_${VERSION}.deb"

# Clean up
rm -rf "$UNPACK_DIR"
echo "==> Repackaging complete. Modified package located at $DST_DIR/modified_${MODULE_NAME}_${VERSION}.deb"
echo "==> Replacing the original package with the modified package."
mv "$DST_DIR/modified_${MODULE_NAME}_${VERSION}.deb" "$DEB_FILE"
echo "==> Done. Final modified package is located at $DEB_FILE"

