# Utilisation d'agents LLM en développement

Un [guide pour coder avec l’IA](https://doc.incubateur.net/communaute/gerer-son-produit/faire-de-lia-chez-beta/guide-pour-coder-avec-lia) est proposé par beta.gouv.fr et c'est une très bonne ressource.

Il recommande notamment de faire tourner les agents dans des VM pour limiter les risques d'accès interdits ou de fuite de données.

L'éditeur reste sur le système hôte, les commandes (rails, ruby, rspec…) tournent dans la VM.

## VM pour Mac Os avec Lima

Installation et usage (depuis la racine du projet) :
- `brew install lima`
- `scripts/devtools/lima-setup.sh`
- `limactl shell devbox` puis `claude` puis `/login` la première fois

La VM n'a accès qu'au répertoire du projet monté en lecture-écriture.
Les fichiers locaux du Mac ne sont pas accessibles, à part les fichiers de configuration des CLI d'agents IA.
Les surcharges spécifiques à la VM (variables d'environnement, config Playwright, utilisateur PostgreSQL) sont dans `~/.env.local` à l'intérieur de la VM.

### Git

Si vous souhaitez permettre aux agents de committer, configurez `user.name` et `user.email` dans la VM :

```bash
limactl shell devbox
git config --global user.name "Prénom Nom"
git config --global user.email "prenom@email.fr"
```

