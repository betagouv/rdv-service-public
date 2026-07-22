# AGENTS.md

Conventions pour les agents IA travaillant sur ce dépôt.

## Langue

Rédige tout en français : commentaires du code, messages de commit, documentation (README, `.md`) et tes réponses à l'utilisateur.
Les identifiants techniques existants (noms de variables, méthodes, fichiers) restent en anglais.

## Linting

Avant d'écrire du Ruby ou du Slim, lis la config du linter concerné (`.rubocop.yml` pour les conventions Ruby ; les règles slim-lint) afin que tes changements respectent les conventions existantes.

- **Ruby (RuboCop) :** `bundle exec rubocop` — ou `bin/rubocop` (via Spring, préfixe automatiquement `.rubocop.yml`). Utilise les plugins `rubocop-rspec` et `rubocop-rails` ; la version Ruby cible est définie par `TargetRubyVersion` dans `.rubocop.yml`. Sur des chemins précis : `bundle exec rubocop <chemins>`.
- **Templates Slim :** `bundle exec slim-lint <fichiers>`. Uniquement sur les templates modifiés, ex. `bundle exec slim-lint app/views/path/to/_partial.html.slim`.
- **Scan de sécurité :** `bundle exec brakeman` (ou `bin/brakeman`).

## Specs

- **RSpec :** `bundle exec rspec <chemins>` — ou `bin/rspec` (via Spring). Cible des fichiers/dossiers précis : `bundle exec rspec spec/features/users/online_booking/`.
- Les specs de feature utilisent Capybara avec le driver Playwright pour les exemples `js: true` ; les factories viennent de `factory_bot`.
- Pour les flux online-booking/ANTS nécessitant l'API ANTS externe, stubbe-la avec `stub_ants_status_ok(...)` (voir les specs existantes).

Lance toujours les linters et specs pertinents après un changement non trivial avant de considérer la tâche terminée.

## Qualité du code

Le plus important lorsque tu proposes des fonctionnalités est de réfléchir aux enjeux de sécurité.
Les changements de permissions ou l'exposition involontaire de données qui ne l'étaient pas jusqu'ici sont à éviter ou alors à indiquer clairement dans les descriptions de PR.

### Environnement de travail

## GitHub CodeSpace

Il est fort possible que tu tournes dans une VM GitHub CodeSpace avec gh installé et loggé pour le user `botadrien`.
Dans ce cas, tu ne dois JAMAIS ouvrir de PR, mettre de commentaire, ou quelconque écriture sur le repo original de l'orga betagouv.
Tu peux tout faire sur le fork `botadrien/rdv-service-public`

## VM devbox Lima

Si la variable d'environnement `RDVSP_DEVBOX_VM` est définie, tu tournes dans la VM devbox Lima créée par `scripts/devtools/lima-vm/host-create-vm.sh`. Implications :

- Postgres et Redis tournent localement dans la VM
- Le dossier du projet est un mount RW
