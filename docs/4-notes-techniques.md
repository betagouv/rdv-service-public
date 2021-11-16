# Tech Tips

Quelques notes à propos de commandes, de scripts et autres bricoles qui nous aident.

## Console SuperAdmin

L’accès à /super_admins se fait:
* en `production` et en `development`, en OAuth via un compte GitHub
    * en `development`, le premier compte à tenter d’accéder est automatiquement ajouté.
* sur les review apps, en http Basic.
    * login: rdv-solidarites
    * password: défini automatiquement au déploiement (cf [scalingo.json](scalingo.json))
    * obtenu avec `scripts/review_app_super_admin_password.sh <numéro de la PR>`

## Tâches automatisées

* `auto_generate_diagram` est ajouté à `db:migrate` pour tenir à jour docs/domain_model.png.
* `schedule_jobs` tourne après chaque `db:migrate` et`db:schema:load` pour ajouter automatiquement les “cron jobs”.
* Dans `cron_job.rb`, outre les tâches métiers (c’est-à-dire les envois de mail et la gestion de file d’attente), il y a un job de gestion de production, `ScalingoAppRestarterJob` dont le rôle est de redémarrer les instances Scalingo chaque nuit. 

## Restore production

Pour tester les migrations avec les données de prod, il faut parfois récupérer un backup de la prod localement. Ça permet aussi de tester que nous arrivons bien à récupérer un backup valable de la production.

L’option la plus simple est d'appeler le script `scripts/scalingo_dump.sh`. Vous aurez besoin d’avoir la cli scalingo installée et configurée. Cela revient à la même chose que télécharger un backup depuis l’interface web, puis de faire un `pg_restore -d development <fichier.pgsql>` manuellement.

Il est recommandé de lancer le serveur local sans le worker sinon il y aura beaucoup de jobs de reminders et de simulations d'envois de mails :

`foreman start -f Procfile.dev  web=1,webpack=1`

## Export Excel sectorisation

> J’ai créé le secteur « Adour BAB Anglet rues » : vous serait-il possible de me faire une extraction excel de ce secteur uniquement svp ?

> Pour info la marche a suivre pour cet export :

```ruby
ruby scripts/scalingo_dump.rb -e production
rails runner scripts/export_sectors.rb 64
```

> Et la j’ai filtré a la main les lignes demandées.

## Liens utiles

- http://localhost:3000/letter_opener
- http://localhost:3000/rails/mailers
- http://localhost:3000/rails/info/routes
- http://localhost:3000/rails/info/properties


#### Tester une WebHook

- copier l’url que te donne `webhook.site` ;
- créer un endpoints, dans la page super admin > webhook, avec cette URL et n'importe quel secret ;
- déclencher des évènements en faisant des actions depuis l'interface _admin_ pour l'organisation associé ;
- les events apparaissent sur ta page webhook.site laissé ouverte.

## Chargement des absences

Pour le 92, nous chargeons les absences à partir d'un fichier CSV. Ce n'est pas intégré à l'application directement parce que ce n'est peut-être pas la finalité de l'application (?). Nous pourrions rediscuter de tout ça.

En attendant, voici comment procéder.
- avoir le fichier CSV quelque part (pour le format, regarder comme le script fonctionne)
- démarrer un serveur local (j'utilise `http-server`, mais un autre conviens aussi) ex: `http-server -p 9998`
- démarrer [NGROK](https://ngrok.com/) pour faire un tunnel. Brancher Ngrok sur le serveur local. ex: `ngrok http 9998`
- NGROK propose une interface web où nous pouvons trouver la liste des fichiers servi. Copier l'url du fichier à charger
- lancer le script sur scalingo en lui passant l'ID de l'organisation où charger les absences et l'URL du fichier. ex: `scalingo --app monApp run rails r scripts/load_absences_csv.rb 285 http://97b6-92-167-177-12.ngrok.io/mon_fichier`


