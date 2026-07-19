#!/usr/bin/env bash
# Prépare une VM Lima devbox. À lancer depuis la racine du projet RDVSP.
set -euo pipefail

PROJECT_DIR="$(pwd)"
VM_NAME="rdvsp-devbox"

if limactl list --format='{{.Name}}' | grep -qx "$VM_NAME"; then
  echo "==> Deleting existing Lima VM '$VM_NAME'..."
  limactl delete --force "$VM_NAME"
fi

mkdir -p "$PROJECT_DIR/tmp/lima-vm-cache/local"

echo "==> Création de la VM Lima…"
# on n'utilise pas encore ubuntu 26 car chromium n'y est pas pré-compilé
limactl start template:ubuntu-24.04 --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y \
  --set ".mounts[0] = {\"location\": \"$PROJECT_DIR\", \"writable\": true}" \
  --set ".mounts[1] = {\"location\": \"$HOME/.claude\", \"writable\": true}" \
  --set ".mounts[2] = {\"location\": \"$HOME/.config/opencode\", \"writable\": true}"

echo "==> Résolution des IP des domaines autorisés…"
ALLOWED_IPS=""
for domain in api.anthropic.com statsig.anthropic.com rubygems.org openrouter.ai models.dev; do
  while IFS= read -r ip; do
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    ALLOWED_IPS="${ALLOWED_IPS}${ip} ${domain}"$'\n'
  done < <(dig +short A "$domain" 2>/dev/null || true)
done

echo "==> Installation des dépendances dans la VM…"
limactl shell "$VM_NAME" -- \
  env PROJECT_DIR="$PROJECT_DIR" HOST_HOME="$HOME" ALLOWED_IPS="$ALLOWED_IPS" VM_NAME="$VM_NAME" \
  bash "$PROJECT_DIR/scripts/devtools/lima-setup-vm-install.sh"

# ~/.claude.json contient les credentials mais est hors du ~/.claude qui est monté
if [[ -f "$HOME/.claude.json" ]]; then
  echo "==> Copie de ~/.claude.json…"
  limactl copy "$HOME/.claude.json" "$VM_NAME:.claude.json"
fi

# auth.json contient les credentials opencode mais est hors du ~/.config/opencode qui est monté
if [[ -f "$HOME/.local/share/opencode/auth.json" ]]; then
  echo "==> Copie de ~/.local/share/opencode/auth.json…"
  limactl copy "$HOME/.local/share/opencode/auth.json" "$VM_NAME:.local/share/opencode/auth.json"
fi


echo ""
echo "La VM '$VM_NAME' est prête. Run: limactl shell $VM_NAME"
