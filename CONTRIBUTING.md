# CONTRIBUTING

## Signaler un problème

Si vous rencontrez un problème avec l'application vous pouvez nous contacter à [contact@rdv-solidarites.fr](mailto:contact@rdv-solidarites.fr) 

## Soumettre une modification

Voici la marche à suivre pour nous soumettre une modification de code
- Clone le projet dans votre environnement
- Créer une branche 
- Apporter les modifications que vous souhaitez en respectant [le guide de programmation](#Guide-de-programmation) 
- Pousser votre code sur github
- Créer une Pull Request

## Guide de programmation

Utilisation des conventions de Ruby on Rails [Rails best practice](https://rails-bestpractices.com/) et [The rails Style Guide](https://github.com/rubocop-hq/rails-style-guide)

### Vues

- Préférer le passage explicites de variables locales à l'utilisation de variables d'instances venant des contrôleurs dans les partials pour permettre plus de généricité

### Tests

- Privilégier les tests unitaires sur les tests bout en bout ;
- Nous allons considérer que les tests unitaires dans rails peuvent inclure ActiveRecord ;
- Chaque élément nécessaire à un test doit se trouver dans un même écran (dans les mêmes ~20 lignes);
- Nous utilisons [RSpec](https://rspec.info/) pour écrire nos tests

#### Exécution des tests (RSpec)

Les tests ont besoin de leur propre base de données et certains d'entre eux utilisent Selenium pour s'exécuter dans un navigateur. N'oubliez pas de créer la base de test et d'installer chrome et chromedriver pour exécuter tous les tests.

Pour exécuter les tests de l'application, plusieurs possibilités :

- Lancer tous les tests

```bash
bin/rspec
```

- Lancer un test en particulier

```bash
bin/rspec file_path/file_name_spec.rb:line_number
```

- Lancer tous les tests d'un fichier

```bash
bin/rspec file_path/file_name_spec.rb
```

#### Linting

Le projet utilise plusieurs linters pour vérifier la lisibilité et la qualité du code.

- Faire tourner tous les linters : `bin/rake ci`
- Demander à Rubocop de corriger les problèmes qu'il rencontre : `bin/rubocop -a`
- Demander à Brakeman de passer en revue les vulnérabilités : `bin/brakeman -I`

#### WebHook

- tu copies l'url que te donne webhook.site ;
- tu vas dans la super admin > webhook endpoints ;
- tu en crées un avec cette URL et n'importe quel secret ;
- tu déclenches des évènements en faisant des actions depuis l'interface _admin_ pour l'organisation associé ;
- les events apparaissent sur ta page webhook.site que tu as bien laissé ouverte.

## D'autres façon de contribuer

Si vous souhaitez contribuer à notre projet, vous pouvez 
- En parler autour de vous 
- Participer à la [documentation](https://doc.rdv-solidarites.fr/)
- Faire des petits gâteaux maisons pour l'équipe de RDV-solidarité (^^)


