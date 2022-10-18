# Paramètres généraux de l'API

L'API de RDV-Solidarités vous permet de lire, créer et modifier des données dans notre base depuis votre logiciel.

Toutes les fonctionnalités de RDV-Solidarités ne sont pas encore disponibles via l’API. Contactez-nous si vous avez besoin de fonctionnalités qui ne sont pas encore présentes.

## API à destination des agents

Merci de vous référer à la documentation suivante: [https://doc.rdv-solidarites.fr/tech/api-interconnexions-entrantes](https://doc.rdv-solidarites.fr/tech/api-interconnexions-entrantes)

## API publique

### Verbe HTTP

Aucune écriture n'étant possible, toutes les routes de l'API publique s'appellent avec le verbe HTTP `GET`.

### Versionnage

L'API est versionnée. La version actuelle est 1.0 (référencée comme v1 dans les points de terminaison)

### Routes

Les points de terminaison de l'API publique sont accessible par une route de la forme : `https://<domain>/public_api/<version>/<endpoint>`

Avec :

- `version` est la version de l'API
- `endpoint` est le nom du point de terminaison

Par exemple, on aura : `https://<domain>/public_api/v1/organizations`

### Pagination des réponses par listes

Tous les points de terminaison qui retournent des listes sont paginés.

Le paramètre (optionnel) `page` permet d'accéder à une page donnée. Le paramètre (optionnel) `per` permet d'indiquer combien d'éléments par page sont retournés. Par défaut, et sauf précision contraire dans la documentation d'un point de terminaison donné, on retrouve 20 éléments par page.

De manière générale, tout point de terminaison qui retourne une liste peut retourner une liste vide.

### Authentification

En phase de prototypage, l'API publique est pour l'instant accessible sans authentification.

### Limites et quotas d'utilisation

L'API publique est soumise à un usage raisonné de la part de ses clients, afin de ne pas dégrader les performances de l'application. Par défaut, et sauf précision contraire dans la documentation d'un point de terminaison donné, l'API peut être appelée 50 fois toutes les 5 minutes.

### Erreurs

L'API publique est susceptible de retourner les erreurs suivantes.

| Code  | Nom                   | Description                            |
| ----  | --------              | --------                               |
| `400` | Bad Request           | La requête est invalide                |
| `401` | Unauthorized          | L'API KEY est manquante ou non fournie |
| `403` | Forbidden             | La limite autorisée est atteinte       |
| `404` | Not Found             | La ressource est introuvable           |
| `500` | Internal Server Error | Une erreur serveur produite            |

L'erreur `401` n'est pertinente que lorsque l'API publique proposera un mécanisme d'authentification.

## Ressources

### Sérialisation

Les ressources sont les éléments renvoyés par les points de terminaison. Elles sont sérialisées en JSON.

### Champs DateTime

Les champs de type DateTime sont formatés avec la norme ISO 8601.
