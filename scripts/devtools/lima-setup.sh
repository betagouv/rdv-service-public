#!/usr/bin/env bash
# Setup a Lima VM (devbox) for rdv-service-public development.
# Run from the root of the project on your Mac.
set -euo pipefail

PROJECT_DIR="$(pwd)"
VM_NAME="devbox"

echo "==> Creating Lima VM..."
# we do not use ubuntu 26 yet because chromium is not pre-built yet
limactl start template:ubuntu-24.04 --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y

echo "==> Configuring mount (read-write, project dir only)..."
LIMA_YAML="$HOME/.lima/$VM_NAME/lima.yaml"
python3 -c "
import re
content = open('$LIMA_YAML').read()
content = re.sub(
    r'mounts:\n- location: \"~\"',
    'mounts:\n- location: \"$PROJECT_DIR\"\n  writable: true\n- location: \"$HOME/.claude\"\n  writable: true\n- location: \"$HOME/.config/kilo\"\n  writable: true',
    content
)
open('$LIMA_YAML', 'w').write(content)
"

echo "==> Restarting VM to apply mount changes..."
limactl stop "$VM_NAME"
limactl start "$VM_NAME"

echo "==> Installing packages, tools, and languages inside VM..."
limactl shell "$VM_NAME" -- bash -c "
  set -euo pipefail

  sudo apt-get update -y && sudo apt-get install -y \
    build-essential curl git vim tmux \
    postgresql redis-server dnsutils

  sudo systemctl enable postgresql redis-server
  sudo systemctl start postgresql redis-server

  # Allow any local user to connect as any PostgreSQL role (dev only)
  sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' /etc/postgresql/16/main/pg_hba.conf
  sudo systemctl reload postgresql
  sudo -u postgres createuser --superuser rdvsp 2>/dev/null || echo 'role rdvsp already exists'

  curl https://mise.run | sh
  export PATH=\"\$HOME/.local/bin:\$PATH\"
  eval \"\$(\$HOME/.local/bin/mise activate bash)\"
  grep -q 'mise activate' ~/.bashrc || echo 'eval \"\$(\$HOME/.local/bin/mise activate bash)\"' >> ~/.bashrc
  echo 'cd $PROJECT_DIR' >> ~/.bashrc

  mise trust --yes $PROJECT_DIR/mise.toml
  cd $PROJECT_DIR && mise install
  export PATH=\"\$HOME/.local/share/mise/shims:\$PATH\"

  # AI agents
  curl -fsSL https://claude.ai/install.sh | bash
  echo 'alias claude=\"claude --dangerously-skip-permissions\"' >> ~/.bashrc
  npm install -g @kilocode/cli

  # Share AI agent config/settings from the host (credentials need separate auth in the VM)
  rm -rf ~/.claude && ln -s $HOME/.claude ~/.claude
  mkdir -p ~/.config && rm -rf ~/.config/kilo && ln -s $HOME/.config/kilo ~/.config/kilo

  # VM-local env overrides (not committed to the project)
  cat > ~/.env.local <<'ENVEOF'
export POSTGRES_USER=rdvsp
ENVEOF
  grep -q 'source ~/.env.local' ~/.bashrc || echo 'source ~/.env.local' >> ~/.bashrc
"

# echo "==> Pre-creating dsfr-assets symlink to avoid race condition in parallel:create..."
# limactl shell "$VM_NAME" -- bash -ic "
#   cd $PROJECT_DIR
#   GEM_PATH=\$(bundle exec ruby -e \"puts Gem.loaded_specs['dsfr-assets'].full_gem_path\")
#   rm -f public/assets/artwork
#   ln -s \"\${GEM_PATH}/vendor/assets/stylesheets/artwork\" public/assets/artwork
# "

echo "==> Running make install..."
limactl shell "$VM_NAME" -- bash -ic "make install"

echo "==> Locking down outbound network (Anthropic API only)..."
limactl shell "$VM_NAME" -- bash -c '
  set -euo pipefail

  # Resolve Anthropic domains to IPs while internet is still available
  ALLOWED_RULES=""
  for domain in api.anthropic.com statsig.anthropic.com; do
    while IFS= read -r ip; do
      [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
      ALLOWED_RULES="${ALLOWED_RULES}    ip daddr ${ip} accept  # ${domain}\n"
    done < <(dig +short A "$domain" 2>/dev/null || true)
  done

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
'

echo ""
echo "VM '$VM_NAME' is ready. Run: limactl shell $VM_NAME"
