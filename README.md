# rdv-solidarites.fr

Réduire le nombre de rendez-vous annulés dans les maisons départementales de solidarité.

https://beta.gouv.fr/startups/lapins.html

[![View performance data on Skylight](https://badges.skylight.io/status/RgR7i58P67xN.svg)](https://oss.skylight.io/app/applications/RgR7i58P67xN)

## Installation pour le développement

### Dépendances techniques

#### Tous environnements

- postgresql

#### Développement

- rbenv : voir https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts
- Yarn : voir https://yarnpkg.com/en/docs/install
- Foreman : voir https://github.com/ddollar/foreman

#### Tests

- Chrome
- chromedriver :
  * Mac : `brew cask install chromedriver`
  * Linux : voir https://sites.google.com/a/chromium.org/chromedriver/downloads

### Initialisation de l'environnement de développement

Afin d'initialiser l'environnement de développement, exécutez la commande suivante :

    bin/setup

### Préparation des variables d'environnement

- `cp .env.sample .env`
- https://www.algolia.com/users/sign_up/places pour renseigner PLACES_APP_ID et PLACES_API_KEY


### Lancement de l'application

    foreman s -f Procfile.dev

L'application tourne à l'adresse `http://localhost:5000`.

### Voir les emails envoyés en local

Ouvrez la page [http://localhost:5000/letter_opener](http://localhost:5000/letter_opener).

### Mise à jour de l'application

Pour mettre à jour votre environnement de développement, installer les nouvelles dépendances et faire jouer les migrations, exécutez :

    bin/update

### Exécution des tests (RSpec)

Les tests ont besoin de leur propre base de données et certains d'entre eux utilisent Selenium pour s'exécuter dans un navigateur. N'oubliez pas de créer la base de test et d'installer chrome et chromedriver pour exécuter tous les tests.

Pour exécuter les tests de l'application, plusieurs possibilités :

- Lancer tous les tests

        bin/rspec

- Lancer un test en particulier

        bin/rspec file_path/file_name_spec.rb:line_number

- Lancer tous les tests d'un fichier

        bin/rspec file_path/file_name_spec.rb

### Linting

Le projet utilise plusieurs linters pour vérifier la lisibilité et la qualité du code.

- Faire tourner tous les linters : `bin/rake ci`
- Demander à Rubocop de corriger les problèmes qu'il rencontre : `bin/rubocop -a
- Demander à Brakeman de passer en revue les vulnérabilités : `bin/brakeman -I

### Régénérer les binstubs

    bundle binstub railties --force
    bin/rake rails:update:bin

### Programmation des jobs

  rake send_reminder # Envoi des sms/email de rappel 48h avant le rdv
  rake file_attente # Envoi des sms/email lorsque des créneaux se libèrent
