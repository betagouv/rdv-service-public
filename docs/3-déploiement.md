# Déploiement

RDV-Solidarités est hébergé chez [Scalingo](https://scalingo.com/fr/datacenters), sur la region Paris / SecNumCloud.

| Instance | domaine | branche | notes |
| -------- | ------- | ------- | ----- |
| production-rdv-solidarites | www.rdv-solidarites.fr | production | review apps activées |
| demo-rdv-solidarites | demo.rdv-solidarites.fr | production | - |
| recette-rdv-solidarites | recette.rdv-solidarites.fr | recette | review apps activées |

## Mise à jour du changelog

Nous tenons à jour [les dernières nouveautés sur la doc](https://doc.rdv-solidarites.fr/dernieres-nouveautes). C'est lié à un répo [Github/rdv-solidarites/rdv-solidarites-doc](https://github.com/rdv-solidarites/rdv-solidarites-doc).

Les tickets de la colonne Done du [tableau de suivi des développements](https://github.com/betagouv/rdv-solidarites.fr/projects/8?fullscreen=true) après les avoir inscrit dans les dernières nouveautés.

Un petit script permet de voir les tickets de cette colonne, et, avec une option `--archive` de les archiver. Il faut copier l'output dans le fichier des dernières nouveautés (en retrouvant le jour qui convient).

Attention, il y a besoin d'un token de github pour executer ce script.

> initial setup:
> head to https://github.com/settings/tokens and create a token with public_repo permission
> store it in your .env like `GITHUB_CHANGELOG_USERPWD=adipasquale:XXXX`

_on peut aussi le mettre sur la ligne de commande ou dans un autre endroit_

```bash
GITHUB_CHANGELOG_USERPWD=xxxx bundle exec ruby scripts/get_deployed_changes.rb --archive
```
