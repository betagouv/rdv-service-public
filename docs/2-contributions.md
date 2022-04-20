# Comment Contribuer

## Signaler un problème

Si vous rencontrez un problème, [contactez-nous par email](mailto:support@rdv-solidarites.fr).

## Soumettre une modification

Les pull requests sont bienvenues ! N’hésitez pas à [nous en parler à l’avance](mailto:contact@rdv-solidarites.fr). La démarche est habituelle: faites un fork, créez une branche, faites un PR. Pour les petites corrections de fautes d’orthographe, n’hésitez pas à proposer une modification directement depuis github.com.

## Style de code

Au delà du style de syntaxe, nous essayons de suivre quelques principes. RDVS-S a déjà plusieurs années, et a été développé par plusieurs équipes successives. C’est pour cette raison qu’on peut trouver plusieurs façons de faire au sein du projet. Aujourd’hui, nous essayons d’aller dans cette direction:

1. Écrire moins de code, et du code plus simple
  - Éviter de créer trop de classes auxiliaires, comme les presenters, form objects, services, etc.
  - Éviter les concerns/modules qui ne servent qu’à un seul modèle ; réserver ça aux fonctionnalités communes.
  - Préférer plutôt la proximité du code avec l’endroit où il est appelé.
2. Plutôt du rails monolithique
  - Minimiser le JS utilisant des API spécifiques
  - à terme, on utilisera hotwire
3. Moins de dépendances externes
  - à terme, on retirera webpack. Peut-être lors la migration à Rails 7.
4. Documenter le code
  - Concrètement, dans les modèles, regrouper en tête de fichier, sous forme de sections:
    - attributs,
    - relations,
    - validations et hooks
    - scopes
5. ActiveRecord
  - utiliser les relation through autant que possible pour construire les queries
6. Pour les tests, utiliser les helpers et rspec avec parcimonie
  - Par exemple, les `let`, `subject`, etc, doivent rester proches de leur lieu d’utilisation, quitte à être répétés dans un autre `context`.

## Linters

Dans l’ensemble, nous suivons les conventions de Ruby on Rails [Rails best practice](https://rails-bestpractices.com/) et [The rails Style Guide](https://github.com/rubocop-hq/rails-style-guide). Nous utilisons aussi largement rubocop; dans tous les cas, le linter alertera en cas de problèmes.

- Faire tourner tous les linters :
```bash
make lint                 Run all linters
make lint_rubocop         Ruby linter
make lint_slim            Slim Linter
make lint_brakeman        Security Checker
```

- Demander à Rubocop de corriger les problèmes qu’il rencontre :
```bash
make autocorrect          Fix autocorrectable lint issues
```

## Tests

Nous utilisons [RSpec](https://rspec.info/) pour écrire nos tests. En principe, la base de données de tests est créée automatiquement. Les feature tests utilisent Capybara et ont besoin de Chrome (et de chromedriver) pour s’exécuter.

- Lancer tous les tests

```bash
make test                 Run all tests
make test_unit            Run unit tests in parallel
make test_features        Run feature tests
```

- Lancer tous les tests d’un fichier

```bash
bin/rspec file_path/file_name_spec.rb
```

- Lancer un test en particulier

```bash
bin/rspec file_path/file_name_spec.rb:line_number
```
