#!/usr/bin/env bash
# Met à jour le pare-feu nftables d'une VM Lima devbox existante, sans la recréer.
# À lancer depuis la racine du projet RDVSP.
#
# Usage : host-update-firewall.sh [nom-vm]

set -euo pipefail

VM_NAME="${1:-rdvsp-devbox}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALLOWED_DOMAINS=(
  # Agents LLM
  api.anthropic.com statsig.anthropic.com openrouter.ai models.dev
  # GitHub
  github.com codeload.github.com objects.githubusercontent.com raw.githubusercontent.com api.github.com
  # Registries de paquets
  registry.npmjs.org pypi.org files.pythonhosted.org rubygems.org crates.io static.crates.io
  # Mise / runtimes
  mise.jdx.dev mise.run
  # APT Ubuntu
  deb.debian.org archive.ubuntu.com security.ubuntu.com ports.ubuntu.com
)

if ! limactl list --format='{{.Name}}' | grep -qx "$VM_NAME"; then
  echo "Erreur : la VM '$VM_NAME' n'existe pas. Lance d'abord host-create-vm.sh." >&2
  exit 1
fi

echo "==> Résolution des IP des domaines autorisés…"
ALLOWED_IPS=""
for domain in "${ALLOWED_DOMAINS[@]}"; do
  while IFS= read -r ip; do
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    ALLOWED_IPS="${ALLOWED_IPS}${ip} ${domain}"$'\n'
  done < <(dig +short A "$domain" 2>/dev/null || true)
done

echo "==> Configuration du pare-feu (nftables) sur '$VM_NAME'…"
limactl shell "$VM_NAME" -- env ALLOWED_IPS="$ALLOWED_IPS" bash "$SCRIPTS_DIR/vm-install-firewall.sh"

echo "Pare-feu mis à jour sur '$VM_NAME'."
