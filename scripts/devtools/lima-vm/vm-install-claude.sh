#!/usr/bin/env bash
# S'exécute dans la VM Lima. Appelé par host-create-vm.sh uniquement avec --claude.
# Variables d'environnement requises : HOST_HOME
set -euo pipefail

curl -fsSL https://claude.ai/install.sh | bash
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc
rm -rf ~/.claude && ln -s "$HOST_HOME/.claude" ~/.claude
