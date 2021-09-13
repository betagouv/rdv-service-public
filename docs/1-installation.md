# Installation

## Prérequis

- Déploiement:
  - Ruby 2.7 (nous conseillons l’utilisation de [rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
  - PostgreSQL >= 12, l’utilisateur doit avoir les droits `superuser`.
- Développement
  - [Yarn](https://yarnpkg.com/en/docs/install)
  - [Foreman](https://github.com/ddollar/foreman)
  - [graphviz](https://voormedia.github.io/rails-erd/install.html) (pour [rails-erd](https://github.com/voormedia/rails-erd)).
  - [Scalingo CLI](https://doc.scalingo.com/cli)

## Setup

Le script se charge d’installer les gems et packages et de créer la base de données.
```bash
make install  ## appelle bin/setup
```

Il ne reste (si tout s’est bien passé) qu’à lancer le serveur.
```bash
make run      ## appelle foreman s -f Procfile.dev
```

## Commandes

Un [Makefile](Makefile) est disponible, qui sert de point d’entrée aux différents outils :

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
help                 Display available commands
```
