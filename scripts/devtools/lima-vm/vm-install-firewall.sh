#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par host-create-vm.sh dans un limactl shell séparé.
# Configure le pare-feu nftables avec les IP résolues par l'hôte.
# Variables d'environnement requises : ALLOWED_IPS
set -euo pipefail

ALLOWED_RULES=""
while IFS=' ' read -r ip domain; do
  [[ -n "$ip" ]] || continue
  ALLOWED_RULES="${ALLOWED_RULES}    ip daddr ${ip} accept  # ${domain}\n"
done <<< "$ALLOWED_IPS"

sudo tee /etc/nftables.conf > /dev/null << EOF
#!/usr/sbin/nft -f
flush ruleset

table ip filter {
  chain output {
    type filter hook output priority 0; policy drop;

    oifname "lo" accept

    # Communication hôte Lima <-> VM
    ip daddr 10.0.0.0/8 accept
    ip daddr 172.16.0.0/12 accept
    ip daddr 192.168.0.0/16 accept

    # DNS
    udp dport 53 accept
    tcp dport 53 accept

    # domaines autorisés
$(printf "%b" "${ALLOWED_RULES}")
  }
}
EOF
sudo systemctl enable nftables
sudo systemctl restart nftables
echo "Pare-feu actif"
