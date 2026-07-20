#!/usr/bin/env bash
# Met à jour le pare-feu nftables d'une VM Lima devbox existante, sans la recréer.
# À lancer depuis la racine du projet RDVSP.
#
# Usage : host-update-firewall.sh [nom-vm]

set -euo pipefail

VM_NAME="${1:-rdvsp-devbox}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "Erreur : jq est requis (brew install jq)." >&2
  exit 1
fi

# Domaines dont on résout l'IP directement : corrects pour des CDN/registries qui servent
# depuis une poignée d'IP stables. GitHub est traité à part (cf plus bas) car il sert
# github.com/api.github.com/etc. depuis un pool d'IP qui tourne : figer une IP résolue une
# fois provoque des blocages intermittents dès que le DNS renvoie une autre IP du pool.
ALLOWED_DOMAINS=(
  # Agents LLM
  api.anthropic.com statsig.anthropic.com openrouter.ai models.dev
  # Registries de paquets
  registry.npmjs.org pypi.org files.pythonhosted.org rubygems.org crates.io static.crates.io tuf-repo-cdn.sigstore.dev
  # Mise / runtimes
  mise.jdx.dev mise.run mise-versions.jdx.dev
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

echo "==> Récupération des plages IP GitHub (api.github.com/meta)…"
# web/api/git couvrent github.com, api.github.com, codeload.github.com, uploads.github.com,
# raw.githubusercontent.com et objects.githubusercontent.com (mêmes plages CIDR partagées).
# codespaces couvre la connexion aux machines Codespaces (gh codespace ssh/create).
GITHUB_META="$(curl -sS -m 10 https://api.github.com/meta)"
for key in web api git codespaces; do
  while IFS= read -r cidr; do
    [[ -n "$cidr" ]] || continue
    ALLOWED_IPS="${ALLOWED_IPS}${cidr} github(${key})"$'\n'
  done < <(echo "$GITHUB_META" | jq -r --arg k "$key" '.[$k][] | select(contains(":") | not)')
done
ALLOWED_IPS="$(printf '%s' "$ALLOWED_IPS" | awk '!seen[$1]++')"$'\n'

echo "==> Configuration du pare-feu (nftables) sur '$VM_NAME'…"
limactl shell "$VM_NAME" -- env ALLOWED_IPS="$ALLOWED_IPS" bash "$SCRIPTS_DIR/vm-install-firewall.sh"

echo "Pare-feu mis à jour sur '$VM_NAME'."
