# Installation

## Prérequis

- Déploiement:
  - Ruby 3.3.5 (nous conseillons l’utilisation de [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
  - PostgreSQL >= 12, l’utilisateur doit avoir les droits `superuser`. C'est nécessaire pour pouvoir activer les extensions utilisés.
- Développement
  - [Yarn](https://yarnpkg.com/en/docs/install)
  - [graphviz](https://voormedia.github.io/rails-erd/install.html) (pour [rails-erd](https://github.com/voormedia/rails-erd)).
  - [redis](https://redis.io/docs/getting-started/installation/)
  - [Scalingo CLI](https://doc.scalingo.com/cli) (OPTIONAL)
  - [Make](https://fr.wikipedia.org/wiki/Make) (OPTIONAL)

## Setup

Exécutez ce script pour installer les gems et packages et créer la base de données :
```bash
make install  ## appelle bin/setup
```

Pour certaines fonctionnalités comme ProConnect ou des appels à des API distantes, vous aurez besoin de récupérer des variables d'env depuis Vaulwarden. Le fichier .env contient des instructions pour chaque variable.

Vous pouvez ensuite lancer le serveur avec :
```bash
make run      ## appelle overmind start -f Procfile.dev
```

## Commandes

Le [Makefile](https://github.com/betagouv/rdv-service-public/blob/production/Makefile) sert de point d’entrée aux différents outils :

```bash
> make help
install              Setup development environment
run                  Start the application (web, jobs et webpack)
lint                 Run all linters
lint_rubocop         Ruby linter
lint_slim            Slim Linter
lint_brakeman        Security Checker
test                 Run all tests
test_unit            Run unit tests in parallel
test_features        Run feature tests
autocorrect          Fix autocorrectable lint issues
clean                Clean temporary files (including weppacks) and logs
generate_db_diagram  Generate docs/domain_model.svg from Rails models
help                 Display available commands
```
