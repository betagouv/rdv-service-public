# CONTRIBUTING

## Signaler un problème

Si vous rencontrez un problème avec l'application vous pouvez nous contacter à contact@rdv-solidarites.fr 

## Soumettre une mofification

Voici la marche à suivre pour nous soumettre une modification de code
- Clone le projet dans votre environement
- Crée une branche 
- Apporter les modifications que vous souhaitez en respectant [le guide de programmation](#Guide-de-programmation) 
- Poussez votre code sur github
- Crée une Pull Request 

## Guide de programmation

### Objectifs

- Mettre en prod aussi fréquemment que possible et d'autant petites releases que possible
- Limiter le stock des "En cours" pQour éviter d'avoir trop de sujets en tête en même temps
- Chaque développeur·se doit pouvoir être autonome dans le processus de déploiement

### Vues

- préférer le passage explicites de variables locales à l'utilisation de variables d'instances venant des controlleurs dans les partials pour permettre plus de généricité

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

## D'autres façon de contribuer

Si vous souhaitez contribuer à notre pojet, vous pouvez 
- En parler autour de vous 
- Participer à la [documentation](https://doc.rdv-solidarites.fr/)
- Faire des petits gâteaux maisons pour l'équipe de RDV-solidarité (^^)


