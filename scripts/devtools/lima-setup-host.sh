#!/usr/bin/env bash
# Setup a Lima VM (devbox) for rdv-service-public development.
# Run from the root of the project on your Mac.
set -euo pipefail

PROJECT_DIR="$(pwd)"
VM_NAME="devbox"

echo "==> Creating Lima VM..."
# we do not use ubuntu 26 yet because chromium is not pre-built yet
limactl start template:ubuntu-24.04 --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y \
  --set ".mounts[0] = {\"location\": \"$PROJECT_DIR\", \"writable\": true}" \
  --set ".mounts[1] = {\"location\": \"$HOME/.claude\", \"writable\": true}" \
  --set ".mounts[2] = {\"location\": \"$HOME/.config/kilo\", \"writable\": true}"

echo "==> Installing packages, tools, and languages inside VM..."
limactl shell "$VM_NAME" -- \
  env PROJECT_DIR="$PROJECT_DIR" HOST_HOME="$HOME" \
  bash "$PROJECT_DIR/scripts/devtools/lima-setup-vm-install.sh"


echo ""
echo "VM '$VM_NAME' is ready. Run: limactl shell $VM_NAME"
