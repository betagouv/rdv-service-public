# Comment Contribuer

## Signaler un problème

Si vous rencontrez un problème, [contactez-nous par email](mailto:support@rdv-solidarites.fr).

## Soumettre une modification

Les pull requests sont bienvenues ! N’hésitez pas à [nous en parler à l’avance](mailto:contact@rdv-solidarites.fr). La démarche est habituelle : faites un fork, créez une branche, faites un PR. Pour les petites corrections de fautes d’orthographe, n’hésitez pas à proposer une modification directement depuis github.com.

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
7. Pour manipuler des dates et heures, il est recommandé d'utiliser `ActiveSupport::TimeWithZone` plutôt que des Time ou des DateTime. Plus d'explications dans [cette PR](https://github.com/betagouv/rdv-solidarites.fr/pull/2955).
8. Lorsque l'on veut fusionner des requêtes SQL structurellement différentes, il est recommandé d'utiliser de sous-requêtes plutôt que de passer de récupérer puis réutiliser des listes d'IDs. La méthode de helper `.where_id_in_subqueries` peut être utilisée pour construire facilement des sous-requêtes.

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

Vous pouvez utiliser un pre-commit hook pour faire tourner les linters sur les fichiers modifiers.
Pour cela ajoutez le fichier `.git/hooks/pre-commit` suivant :

```bash
#!/bin/bash

echo -en "Validation rubocop_ ⏳"

git diff --cached --name-only | xargs rubocop --force-exclusion --parallel

if [ $? -ne 0 ]; then
        echo "❌ La validation rubocop a échouée"
        exit 1
fi

echo -e "\rValidation rubocop… ✅"
echo -en "Validation slim-lint_ ⏳"

git diff --cached --name-only | grep '^.*\.slim$' | xargs bundle exec slim-lint

if [ $? -ne 0 ]; then
        echo "❌ La validation slim-lint a échouée"
        exit 1
fi

echo -e "\rValidation slim-lint_ ✅"

exit 0
```
Cette proposition de hook fera la validation rubocop et slim-lint sur les fichiers modifiés avant de faire le commit. Si l'un des deux échoue, le commit sera annulé.
Il est possible d’ignorer cette validation en ajoutant l’option `--no-verify` à la commande de commit.

## Tests

Note : nos bonnes pratiques sur les tests sont à lire ici : [Bonnes pratiques de test](bonnes-pratiques-de-tests.md)

Nous utilisons [RSpec](https://rspec.info/) pour écrire nos tests. En principe, la base de données de tests est créée automatiquement. 

Les feature tests utilisent Capybara et ont besoin de Chrome (et de chromedriver) pour s’exécuter. Pour plusieurs devs sous MacOS dans l'équipe, il a fallu ajouter cette ligne à son fichier `/etc/hosts` pour pouvoir faire tourner les tests en local :

    127.0.0.1 www.rdv-solidarites-test.localhost

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

## Workflow de merge des pull requests

Afin de garder un historique git lisible et navigable par `git blame`, nous recommandons l'une de ces deux façons de merger une PR :

- Utiliser _"Squash and merge"_ si les commits de la PR n'apportent pas individuellement de valeur explicative sur le contexte.
- Utiliser _"Create a merge commit"_ si la PR contient des commits qui permettent de mieux comprendre les différents changements indépendants introduits dans la PR.

Au sein de notre projet, il est assumé que la majorité du contexte autour du changement est trouvable dans la PR et non dans les commits. Cependant, il est tout à fait possible de conserver ses commits si on les a bien créés pour qu'ils permettent d'obtenir rapidement une synthèse du contexte via `git blame`.

Par exemple, si au sein d'une même PR on effectue un (petit 🤞) refactor puis une évolution fonctionnelle, il est apprécié que le refactor fasse l'objet d'un commit séparé.

Note : il est possible de réécrire son historique de commits juste avant de merger, si des commits correctifs ont été ajoutés durant la revue.

Un point d'attention : si vous avez mergé la branche `production` dans votre branche de feature pendant la vie de votre PR, veillez à ce que ces commits de merge ne finissent pas dans `production`. Pour ce faire :
- si vous utilisez un squash merge, ces commits vont disparaître
- si vous mergez dans `production` le plus pratique est de rebase votre branche sur `production` avant de merger.

Note : lorsque votre feature branch n'est plus à jour par rapport à `production`, GitHub affiche un avertissement "This branch is out-of-date with the base branch" et vous propose de remédier à la situation. Ce faisant, on déclenche une CI qui teste le code tel qu'il serait s'il était mergé. Si cette CI passe, on peut alors merger.
