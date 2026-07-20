#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par host-create-vm.sh.
# Variables d'environnement requises : PROJECT_DIR, HOST_HOME, VM_NAME

set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y build-essential curl git vim tmux postgresql redis-server dnsutils
sudo systemctl enable postgresql redis-server
sudo systemctl start postgresql redis-server

sudo systemctl disable --now motd-news.timer # système d'annonces ubuntu

# config Postgres
sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' /etc/postgresql/16/main/pg_hba.conf
sudo systemctl reload postgresql
sudo -u postgres createuser --superuser rdvsp 2>/dev/null || echo 'role rdvsp already exists'
echo 'export POSTGRES_USER=rdvsp' >> ~/.bashrc
export POSTGRES_USER=rdvsp

# Installe mise puis ruby, node et yarn
rm -rf ~/.local && ln -s "$PROJECT_DIR/tmp/lima-vm-cache/local" ~/.local
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
cd "$PROJECT_DIR" && mise trust && mise install && mise reshim
echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> ~/.bashrc
export PATH="$HOME/.local/share/mise/shims:$PATH"

# tweaks
echo "cd $PROJECT_DIR" >> ~/.bashrc # toujours ouvrir le terminal dans le repo
echo "export RDVSP_DEVBOX=${VM_NAME}" >> ~/.bashrc # permet aux agents d'identifier qu'ils tournent dans la VM

make install
