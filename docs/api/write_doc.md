Pour chaque endpoint, utiliser [le DSL rswag](https://github.com/rswag/rswag) pour générer les points suivants dans la documentation :

- Description
- Format de données (JSON)
- Schéma d'authentification
- Schéma de données
- Paramètres de la requête
- Exemple de requête
- Exemple de réponse (header et body)

Pour générer la documentation de l'API, utilisez la commande : 

```sh
SWAGGER_DRY_RUN=0 RAILS_ENV=test rails rswag
```