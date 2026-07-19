#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par lima-setup-host.sh via limactl shell.
# Variables d'environnement requises : PROJECT_DIR, HOST_HOME, ALLOWED_IPS
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y build-essential curl git vim tmux postgresql redis-server dnsutils
sudo systemctl enable postgresql redis-server
sudo systemctl start postgresql redis-server

# configuration Postgres pour autoriser tout utilisateur local à se connecter avec n'importe quel rôle
sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' /etc/postgresql/16/main/pg_hba.conf
sudo systemctl reload postgresql
sudo -u postgres createuser --superuser rdvsp 2>/dev/null || echo 'role rdvsp already exists'
echo 'export POSTGRES_USER=rdvsp' >> ~/.bashrc
export POSTGRES_USER=rdvsp

# Installe mise puis ruby, node, yarn
rm -rf ~/.local && ln -s "$PROJECT_DIR/tmp/lima-vm-cache/local" ~/.local # cache persisté pour mise et les gems
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
cd "$PROJECT_DIR" && mise trust && mise install && mise reshim
echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> ~/.bashrc
export PATH="$HOME/.local/share/mise/shims:$PATH"

# toujours ouvrir bash dans le dossier du projet
echo "cd $PROJECT_DIR" >> ~/.bashrc

# Installe Claude
curl -fsSL https://claude.ai/install.sh | bash
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc
rm -rf ~/.claude && ln -s "$HOST_HOME/.claude" ~/.claude

# Dépendances spécifiques du projet
make install

# config pare-feu : règles nftables pour les IP résolues par l'hôte (ALLOWED_IPS)
ALLOWED_RULES=""
while IFS=' ' read -r ip domain; do
  [[ -n "$ip" ]] || continue
  ALLOWED_RULES="${ALLOWED_RULES}    ip daddr ${ip} accept  # ${domain}\n"
done <<< "$ALLOWED_IPS"

# configurer les règles pour autoriser uniquement ces domaines
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
