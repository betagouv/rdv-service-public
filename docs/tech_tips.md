# Tech Tips

Quelques notes à propos de commandes, de scripts et autres bricoles qui nous aident.

## Restore production

Pour tester les migrations avec les données de prod, il faut parfois récupérer un backup de la prod localement. Ça permet aussi de tester que nous arrivons bien à récupérer un backup valable de la production.

L'option la plus simple est d'appeler le script `rails runner scripts/scalingo_dump.rb`. Il vous faudra au préalable rajouter une clé d'API Scalingo dans votre fichier `.env` local - c'est expliqué dans la source du script.

Une autre option est de passer par l'interface de Scalingo, dans l'extension PostGreSQL, télécharger le dernier backup puis lancer la commande suivante.

```bash
pg_restore -d rdv_solidarites_production_dump ~/Downloads/20210128000000_production__6670.pgsql
```

Il est recommandé de lancer le serveur local sans le worker sinon il y aura beaucoup de jobs de reminders et de simulations d'envois de mails :

`overmind start -f Procfile.dev --processes web,webpack`

## Code d'authentification http basic pour le super admin d'une review app

Le login est `rdv-solidarites` et pour le mot de passe :

```bash
scalingo env -a demo-rdv-solidarites-pr1153 --region osc-secnum-fr1 | grep BASIC | sed 's/.*=//' | pbcopy
```

## Mise à jour du changelog

Nous tenons à jour [les dernières nouveautés sur la doc](https://doc.rdv-solidarites.fr/dernieres-nouveautes). C'est lié à un répo [Github/rdv-solidarites/rdv-solidarites-doc](https://github.com/rdv-solidarites/rdv-solidarites-doc).

L'idée c'est d'archiver les ticket de la colonne done du [tableau de suivi des développements](https://github.com/betagouv/rdv-solidarites.fr/projects/8?fullscreen=true) après les avoir inscrit dans les dernières nouveautés.

Un petit script permet de voir les tickets de cette colonne, et, avec une option `--archive` de les archiver. Il faut copier l'output dans le fichier des dernières nouveautés (en retrouvant le jour qui convient).

Attention, il y a besoin d'un token de github pour executer ce script.

> initial setup:
> head to https://github.com/settings/tokens and create a token with public_repo permission
> store it in your .env like `GITHUB_CHANGELOG_USERPWD=adipasquale:XXXX`

_on peut aussi le mettre sur la ligne de commande ou dans un autre endroit_

```bash
GITHUB_CHANGELOG_USERPWD=xxxx bundle exec ruby scripts/get_deployed_changes.rb --archive
```

## Export Excel sectorisation

> J’ai créé le secteur « Adour BAB Anglet rues » : vous serait-il possible de me faire une extraction excel de ce secteur uniquement svp ?

> Pour info la marche a suivre pour cet export :

```ruby
ruby scripts/scalingo_dump.rb -e production
rails runner scripts/export_sectors.rb 64
```

> Et la j’ai filtré a la main les lignes demandées.
