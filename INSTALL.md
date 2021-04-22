# INSTALL
## Prérequis

- Ruby 2.7.2 (nous conseillons l'utilisation de [Rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
- postgresql

## Développement

- Yarn : voir https://yarnpkg.com/en/docs/install
- Foreman : voir https://github.com/ddollar/foreman
- graphviz, pour rails-erd : voir https://voormedia.github.io/rails-erd/install.html

# Commandes

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
Pour acceder à l'interface SuperAdmin créez un compte via la console Rails :

```
bundle exec rails console
SuperAdmin.create!(email: 'email_associated_to_your_github_account@prov.com')
```

## Tâches automatisées

* `auto_generate_diagram` est ajouté à `db:migrate` pour tenir à jour docs/domain_model.png.
* `schedule_jobs` tourne après chaque `db:migrate` et`db:schema:load` pour ajouter automatiquement les “cron jobs”.
