#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par lima-setup-host.sh via limactl shell.
# Variables d'environnement requises : PROJECT_DIR, HOST_HOME, ALLOWED_IPS, VM_NAME
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

# Installe opencode
curl -fsSL https://opencode.ai/install | bash
echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
mkdir -p ~/.config ~/.local/share/opencode
rm -rf ~/.config/opencode && ln -s "$HOST_HOME/.config/opencode" ~/.config/opencode

# Permet aux agents de savoir qu'ils tournent dans cette devbox :
# - export dans ~/.bashrc (hérité par tout processus lancé depuis un shell interactif, ex. un agent et ses sous-processus)
# - /etc/environment pour les sessions gérées par PAM
# - fichier /etc/rdvsp-devbox pour les outils qui n'héritent pas de l'environnement
echo "export RDVSP_DEVBOX=${VM_NAME}" >> ~/.bashrc
echo "RDVSP_DEVBOX=${VM_NAME}" | sudo tee -a /etc/environment > /dev/null
sudo tee /etc/rdvsp-devbox > /dev/null << EOF
You are inside the Lima devbox VM '${VM_NAME}' for the RDVSP project.
- Postgres and Redis run locally in this VM; the project dir is a live mount of the host checkout.
- Outbound traffic is restricted by an nftables allowlist (see /etc/nftables.conf); requests to other domains will fail.
EOF

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
