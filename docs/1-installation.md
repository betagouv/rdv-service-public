# Installation

## Prérequis

- Déploiement:
  - Ruby 3.3.3 (nous conseillons l’utilisation de [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
  - PostgreSQL >= 12, l’utilisateur doit avoir les droits `superuser`. C'est nécessaire pour pouvoir activer les extensions utilisés.
- Développement
  - [Yarn](https://yarnpkg.com/en/docs/install)
  - [graphviz](https://voormedia.github.io/rails-erd/install.html) (pour [rails-erd](https://github.com/voormedia/rails-erd)).
  - [redis](https://redis.io/docs/getting-started/installation/)
  - [Scalingo CLI](https://doc.scalingo.com/cli) (OPTIONAL)
  - [Make](https://fr.wikipedia.org/wiki/Make) (OPTIONAL)

## Setup

Commencer par copier `.env.sample` vers `.env` et définissez-y les variables POSTGRES_HOST, POSTGRES_USER et POSTGRES_PASSWORD pour la connexion à la db locale

Puis exécuter ce script pour installer les gems et packages et créer la base de données :
```bash
make install  ## appelle bin/setup
```

Il ne reste (si tout s’est bien passé) qu’à lancer le serveur.
```bash
make run      ## appelle foreman s -f Procfile.dev
```

## Commandes

Un [Makefile](https://github.com/betagouv/rdv-solidarites.fr/blob/production/Makefile) est disponible, qui sert de point d’entrée aux différents outils :

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
