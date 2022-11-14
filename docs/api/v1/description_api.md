L'API de RDV-Solidarités vous permet de lire des données dans notre base depuis votre logiciel.

Toutes les fonctionnalités de RDV-Solidarités ne sont pas encore disponibles via l’API. Contactez-nous si vous avez besoin de fonctionnalités qui ne sont pas encore présentes.

# Authentification

Certains points de terminaison sont authentifiés. Pour savoir comment y accéder, merci de vous référer à la documentation suivante : [authentification de l'API](https://rdv-solidarites.gitbook.io/guides-pour-rdv-solidarites/tech/api-interconnexions-entrantes/authentification-and-permissions).

# Verbe HTTP

On utilise les verbes HTTP conventionnels pour manipuler les ressources :

- Lecture : `GET`
- Création : `POST`
- Mise à jour : `PATCH`
- Suppression : `DELETE`

# Versionnage

L'API est versionnée. La version actuelle est 1.0 (référencée comme v1 dans les points de terminaison).

# Routes

Les points de terminaison de l'API sont accessible par une route de la forme : `https://<domain>/api/<version>/<endpoint>`.

Avec :

- `version` est la version de l'API
- `endpoint` est le nom du point de terminaison

Par exemple, on aura : `https://<domain>/api/v1/absences`

# Sérialisation

Les ressources sont les éléments renvoyés par les points de terminaison. Elles sont sérialisées en JSON.

# Pagination des réponses par listes

Tous les points de terminaison qui retournent des listes sont paginés.

Le paramètre (optionnel) `page` permet d'accéder à une page donnée. Sauf précision contraire dans la documentation d'un point de terminaison donné, on retrouve 100 éléments par page.

De manière générale, tout point de terminaison qui retourne une liste peut retourner une liste vide.

# Rate limiting

L'utilisation de l'API est limitée pour les points de terminaison sans authentification. Vous pouvez effectuer au maximum 50 appels par minutes. Si vous dépassez cette limite, une erreur 429 vous sera renvoyée et vous trouverez le temps que vous devez attendre avant de relancer une requête dans le header (`Retry-After`).

# Erreurs

L'API est susceptible de retourner les erreurs suivantes :

| Code  | Nom                   | Description                            |
| ----  | --------              | --------                               |
| `400` | Bad Request           | La requête est invalide                |
| `401` | Unauthorized          | L'authentification a échoué            |
| `403` | Forbidden             | La limite autorisée est atteinte       |
| `404` | Not Found             | La ressource est introuvable           |
| `422` | Unprocessable Entity  | La donnée transmise est mal formattée  |
| `429` | Too Many Requests     | Trop de requêtes ont été effectuées    |
| `500` | Internal Server Error | Une erreur serveur produite            |
