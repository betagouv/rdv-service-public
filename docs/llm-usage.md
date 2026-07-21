# Utilisation d'agents LLM en développement

Un [guide pour coder avec l’IA](https://doc.incubateur.net/communaute/gerer-son-produit/faire-de-lia-chez-beta/guide-pour-coder-avec-lia) est proposé par beta.gouv.fr et c'est une très bonne ressource.

Il recommande notamment de faire tourner les agents dans des VM pour limiter les risques d'accès interdits ou de fuite de données.

L'éditeur reste sur le système hôte, les commandes (rails, ruby, rspec…) tournent dans la VM.

## VM sandboxée avec Lima

Installation et usage (depuis la racine du projet) :
- `brew install lima`
- `scripts/devtools/lima-vm/host-create-vm.sh`
- `limactl shell devbox` puis par exemple `claude` puis `/login` la première fois

La VM n'a accès qu'au répertoire du projet RDVSP monté en lecture-écriture et aux fichiers de configuration des CLI d'agents IA.

On ne met pas en place de pare-feu (type nftables) car il serait désactivable par les agents, et que c'est très gênant à l'usage.

