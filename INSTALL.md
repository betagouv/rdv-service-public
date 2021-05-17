# INSTALL

## Prérequis

- Ruby 2.7.3 (nous conseillons l'utilisation de [Rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
- PostgreSQL >= 12, l'utilisateur doit avoir les droits `superuser`

## Développement

- Yarn : voir https://yarnpkg.com/en/docs/install
- Foreman : voir https://github.com/ddollar/foreman
- graphviz, pour rails-erd : voir https://voormedia.github.io/rails-erd/install.html

## Commandes

Voir le [Makefile](Makefile):

```bash
> make help
install              Setup development environment
run                  Start the application (web, jobs et webpack)
lint                 Check code style
test                 Run spec suite
autocorrect          Fix autocorrectable lint issues
clean                Clean temporary files (including weppacks) and logs
help                 Display available commands
```

## Console SuperAdmin

L’accès à /super_admins se fait 
* en `production` et en `development`, en OAuth via un compte GitHub
  * en `development`, le premier compte à tenter d’accéder est automatiquement ajouté.
* sur les review apps, en http Basic.
  * login: rdv-solidarites
  * password: défini automatiquement au déploiement (cf [scalingo.json](scalingo.json))
  * obtenu avec `scripts/review_app_super_admin_password.sh <numéro de la PR>`

## Tâches automatisées

* `auto_generate_diagram` est ajouté à `db:migrate` pour tenir à jour docs/domain_model.png.
* `schedule_jobs` tourne après chaque `db:migrate` et`db:schema:load` pour ajouter automatiquement les “cron jobs”.
