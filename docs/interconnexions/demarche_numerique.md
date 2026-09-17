# Démarche Numérique

Pour tester l'intégration avec Démarche Numérique (DN), vous pouvez faire tourner un serveur DN en local.

Vous pouvez l'installer en clonant le code de https://github.com/demarche-numerique/demarche.numerique.gouv.fr, puis en suivant les instructions (c'est une appli Rails assez classique).

Vous devez ensuite ajouter les lignes suivantes au .env de DN :
```
RDV_SERVICE_PUBLIC_URL="http://www.rdv-etat.localhost:3000"
RDV_SERVICE_PUBLIC_OAUTH_APP_ID="oE-BQa9tyxXcwqmyT5wCuXymbNCfwIlLSFMmWfv6XO8"
RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET="development-A39QXp76ICRMmYqn_STrwsiLXYdkj2u4CtF9R8IgwnA"
```

Ces credentials correspondent à l'appli Oauth générée par `db/seeds/demarche_numerique.rb`.

Il faudra ensuite activer la fonctionnalité "Rendez-vous" via le système de feature flag de DN. Ouvrez une console DN avec `rails c`, puis faites `Flipper.enable :rdv`.

Vous pouvez ensuite démarrer DN sur le port 3002 avec un simple `rails server --port=3002`, et vous connecter sur `localhost:3002` avec le compte `admin@exemple.fr` et le mot de passe `this is a very complicated password !`.


Vous pouvez activer la prise de rendez-vous sur une démarche depuis la page de Gestion de la démarche.
