#!/usr/bin/env bash
# Prépare une VM Lima devbox. À lancer depuis la racine du projet RDVSP.
#
# Usage : host-create-vm.sh [--claude] [--opencode]

set -euo pipefail

INSTALL_CLAUDE=false
INSTALL_OPENCODE=false
for arg in "$@"; do
  case "$arg" in
    --claude) INSTALL_CLAUDE=true ;;
    --opencode) INSTALL_OPENCODE=true ;;
  esac
done

PROJECT_DIR="$(pwd)"
VM_NAME="rdvsp-devbox"
SCRIPTS_DIR="$PROJECT_DIR/scripts/devtools/lima-vm"

if limactl list --format='{{.Name}}' | grep -qx "$VM_NAME"; then
  echo "==> Suppression de la VM Lima existante '$VM_NAME'…"
  limactl delete --force "$VM_NAME"
fi

mkdir -p "$PROJECT_DIR/tmp/lima-vm-cache/local"

echo "==> Création de la VM Lima…"
SET_ARGS=(
  --set ".mounts[0] = {\"location\": \"$PROJECT_DIR\", \"writable\": true}"
)
if [[ "$INSTALL_CLAUDE" == "true" ]]; then
  SET_ARGS+=(--set ".mounts[1] = {\"location\": \"$HOME/.claude\", \"writable\": true}")
fi
if [[ "$INSTALL_OPENCODE" == "true" ]]; then
  SET_ARGS+=(--set ".mounts[2] = {\"location\": \"$HOME/.config/opencode\", \"writable\": true}")
fi

limactl start template:ubuntu-24.04 --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y "${SET_ARGS[@]}"

echo "==> Installation des dépendances…"
limactl shell "$VM_NAME" -- env PROJECT_DIR="$PROJECT_DIR" HOST_HOME="$HOME" VM_NAME="$VM_NAME" bash "$SCRIPTS_DIR/vm-install-dependencies.sh"

if [[ "$INSTALL_CLAUDE" == "true" ]]; then
  echo "==> Installation de Claude…"
  limactl shell "$VM_NAME" -- env HOST_HOME="$HOME" bash "$SCRIPTS_DIR/vm-install-claude.sh"

  if [[ -f "$HOME/.claude.json" ]]; then
    limactl copy "$HOME/.claude.json" "$VM_NAME:.claude.json"
  fi
fi

if [[ "$INSTALL_OPENCODE" == "true" ]]; then
  echo "==> Installation d'opencode…"
  limactl shell "$VM_NAME" -- env HOST_HOME="$HOME" bash "$SCRIPTS_DIR/vm-install-opencode.sh"

  if [[ -f "$HOME/.local/share/opencode/auth.json" ]]; then
    limactl copy "$HOME/.local/share/opencode/auth.json" "$VM_NAME:.local/share/opencode/auth.json"
  fi
fi

echo ""
echo "La VM '$VM_NAME' est prête. Run: limactl shell $VM_NAME"
