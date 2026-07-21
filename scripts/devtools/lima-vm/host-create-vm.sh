#!/usr/bin/env bash
# Prépare une VM Lima devbox. À lancer depuis la racine du projet RDVSP.
#
# Usage : host-create-vm.sh

set -euo pipefail

PROJECT_DIR="$(pwd)"
VM_NAME="rdvsp-devbox"
SCRIPTS_DIR="$PROJECT_DIR/scripts/devtools/lima-vm"

if limactl list --format='{{.Name}}' | grep -qx "$VM_NAME"; then
  echo "==> Suppression de la VM Lima existante '$VM_NAME'…"
  limactl delete --force "$VM_NAME"
fi

mkdir -p "$PROJECT_DIR/tmp/lima-vm-cache/local"

limactl start template:ubuntu-24.04 --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y \
  --set ".mounts[0] = {\"location\": \"$PROJECT_DIR\", \"writable\": true}" \
  --set ".mounts[1] = {\"location\": \"$HOME/.claude\", \"writable\": true}"

echo "==> Installation des dépendances dans la VM…"
limactl shell "$VM_NAME" -- env PROJECT_DIR="$PROJECT_DIR" HOST_HOME="$HOME" VM_NAME="$VM_NAME" bash "$SCRIPTS_DIR/vm-setup.sh"

limactl copy "$HOME/.claude.json" "$VM_NAME:.claude.json"

echo ""
echo "La VM '$VM_NAME' est prête. Run: limactl shell $VM_NAME"
