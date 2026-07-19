#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par host-create-vm.sh uniquement avec --opencode.
# Variables d'environnement requises : HOST_HOME
set -euo pipefail

curl -fsSL https://opencode.ai/install | bash
echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
mkdir -p ~/.config ~/.local/share/opencode
rm -rf ~/.config/opencode && ln -s "$HOST_HOME/.config/opencode" ~/.config/opencode
