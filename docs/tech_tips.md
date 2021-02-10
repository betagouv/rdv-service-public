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

```bash
scalingo env -a demo-rdv-solidarites-pr1153 --region osc-secnum-fr1 | grep BASIC | sed 's/.*=//' | pbcopy
```
