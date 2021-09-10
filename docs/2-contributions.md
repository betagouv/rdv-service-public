# Comment Contribuer

## Signaler un problème

Si vous rencontrez un problème, [contactez-nous par email](mailto:contact@rdv-solidarites.fr).

## Soumettre une modification

Les pull requests sont bienvenues ! N’hésitez pas à [nous en parler à l’avance](mailto:contact@rdv-solidarites.fr). La démarche est habituelle: faites un fork, créez une branche, faites un PR. Pour les petites corrections de fautes d’orthographe, n’hésitez pas à proposer une modification directement depuis github.com.

## Style de code

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
