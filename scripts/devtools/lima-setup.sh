#!/usr/bin/env bash
# Setup a Lima VM (devbox) for rdv-service-public development.
# Run from the root of the project on your Mac.
set -euo pipefail

PROJECT_DIR="$(pwd)"
VM_NAME="devbox"

echo "==> Creating Lima VM..."
limactl start --name="$VM_NAME" --cpus=4 --memory=4 --disk=20 -y

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

echo "==> Setting up SSH config..."
mkdir -p ~/.ssh/config.d
ln -sf "$HOME/.lima/$VM_NAME/ssh.config" ~/.ssh/config.d/"$VM_NAME"
grep -q "Include config.d/\*" ~/.ssh/config 2>/dev/null || echo "Include config.d/*" >> ~/.ssh/config

echo "==> Installing packages, tools, and languages inside VM..."
limactl shell "$VM_NAME" -- bash -c "
  set -euo pipefail

  sudo apt-get update -y && sudo apt-get install -y \
    build-essential curl git vim tmux \
    postgresql redis-server chromium-browser

  sudo systemctl enable postgresql redis-server
  sudo systemctl start postgresql redis-server

  # Allow any local user to connect as any PostgreSQL role (dev only)
  sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' /etc/postgresql/18/main/pg_hba.conf
  sudo systemctl reload postgresql
  sudo -u postgres createuser --superuser rdvsp 2>/dev/null || echo 'role rdvsp already exists'

  # Configure git — update with your own name and email
  # git config --global user.name 'Your Name'
  # git config --global user.email 'your@email.com'

  curl https://mise.run | sh
  export PATH=\"\$HOME/.local/bin:\$PATH\"
  eval \"\$(\$HOME/.local/bin/mise activate bash)\"
  grep -q 'mise activate' ~/.bashrc || echo 'eval \"\$(\$HOME/.local/bin/mise activate bash)\"' >> ~/.bashrc
  echo 'cd $PROJECT_DIR' >> ~/.bashrc

  mise trust $PROJECT_DIR/mise.toml
  cd $PROJECT_DIR && mise install

  # AI agents
  curl -fsSL https://claude.ai/install.sh | sh
  echo 'alias claude=\"claude --dangerously-skip-permissions\"' >> ~/.bashrc
  npm install -g @kilocode/cli

  # Share AI agent config/settings from the Mac host (credentials need separate auth in the VM)
  rm -rf ~/.claude && ln -s $HOME/.claude ~/.claude
  mkdir -p ~/.config && rm -rf ~/.config/kilo && ln -s $HOME/.config/kilo ~/.config/kilo

  # VM-local env overrides (not committed to the project)
  cat > ~/.env.local <<'ENVEOF'
export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser
export SKIP_PLAYWRIGHT_INSTALL=1
export POSTGRES_USER=rdvsp
ENVEOF
  grep -q 'source ~/.env.local' ~/.bashrc || echo 'source ~/.env.local' >> ~/.bashrc
"

echo "==> Pre-creating dsfr-assets symlink to avoid race condition in parallel:create..."
limactl shell "$VM_NAME" -- bash -ic "
  cd $PROJECT_DIR
  GEM_PATH=\$(bundle exec ruby -e \"puts Gem.loaded_specs['dsfr-assets'].full_gem_path\")
  rm -f public/assets/artwork
  ln -s \"\${GEM_PATH}/vendor/assets/stylesheets/artwork\" public/assets/artwork
"

echo "==> Running make install..."
limactl shell "$VM_NAME" -- bash -ic "make install"

echo ""
echo "VM '$VM_NAME' is ready. Run: limactl shell $VM_NAME"
