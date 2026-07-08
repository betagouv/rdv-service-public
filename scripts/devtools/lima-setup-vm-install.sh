#!/usr/bin/env bash
# Runs inside Lima VM. Called by lima-setup.sh via limactl shell.
# Required env vars: PROJECT_DIR, HOST_HOME
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y build-essential curl git vim tmux postgresql redis-server dnsutils

sudo systemctl enable postgresql redis-server
sudo systemctl start postgresql redis-server

# Allow any local user to connect as any PostgreSQL role (dev only)
sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' /etc/postgresql/16/main/pg_hba.conf
sudo systemctl reload postgresql
sudo -u postgres createuser --superuser rdvsp 2>/dev/null || echo 'role rdvsp already exists'

# Installer mise puis ruby, node, yarn
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
eval "$($HOME/.local/bin/mise activate bash)"
grep -q 'mise activate' ~/.bashrc || echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> ~/.bashrc
echo "cd $PROJECT_DIR" >> ~/.bashrc
mise --yes trust "$PROJECT_DIR/mise.toml"
cd "$PROJECT_DIR" && mise install
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Installer les agents IA (seulement Claude)
curl -fsSL https://claude.ai/install.sh | bash
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc

# Share AI agent config/settings from the host (credentials need separate auth in the VM)
rm -rf ~/.claude && ln -s "$HOST_HOME/.claude" ~/.claude

# VM-local env overrides (not committed to the project)
cat > ~/.env.local <<'ENVEOF'
export POSTGRES_USER=rdvsp
ENVEOF
grep -q 'source ~/.env.local' ~/.bashrc || echo 'source ~/.env.local' >> ~/.bashrc

source ~/.env.local
make install

# --- NETWORK

# récupérer les IP des domaines autorisés
ALLOWED_RULES=""
for domain in api.anthropic.com statsig.anthropic.com; do
  while IFS= read -r ip; do
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    ALLOWED_RULES="${ALLOWED_RULES}    ip daddr ${ip} accept  # ${domain}\n"
  done < <(dig +short A "$domain" 2>/dev/null || true)
done

# configurer les règles pour autoriser uniquement ces domaines
sudo tee /etc/nftables.conf > /dev/null << EOF
#!/usr/sbin/nft -f
flush ruleset

table ip filter {
  chain output {
    type filter hook output priority 0; policy drop;

    oifname "lo" accept

    # Lima host<->VM communication (mounts, port forwarding)
    ip daddr 10.0.0.0/8 accept
    ip daddr 172.16.0.0/12 accept
    ip daddr 192.168.0.0/16 accept

    # DNS
    udp dport 53 accept
    tcp dport 53 accept

    # Anthropic API (resolved at setup time; re-run setup if IPs change)
$(printf "%b" "${ALLOWED_RULES}")
  }
}
EOF

sudo systemctl enable nftables
sudo systemctl restart nftables
echo "Firewall active: all outbound internet blocked except Anthropic API."
