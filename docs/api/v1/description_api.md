L'API de RDV-Solidarités vous permet de lire des données dans notre base depuis votre logiciel.

Toutes les fonctionnalités de RDV-Solidarités ne sont pas encore disponibles via l’API. Contactez-nous si vous avez besoin de fonctionnalités qui ne sont pas encore présentes.

# Verbe HTTP

On utilise les verbes HTTP conventionnels pour manipuler les ressources :

- Lecture : `GET`
- Création : `POST`
- Mise à jour : `PATCH`
- Suppression : `DELETE`

# Authentification

Certains points de terminaison sont réservés aux agents authentifiés, dans la limite de leur rôle au sein de l'application.

## Headers d'authentification

Tous les agents peuvent utiliser l'API. Les requêtes faites sur l'API sont authentifiées grace à des tokens d'accès associés à chaque agent. Chaque action faite via l'API est donc attribuable à un agent.

Pour récupérer le token d'accès d'un agent il faut faire une première requête `POST` à l'url `https://www.rdv-solidarites.fr/api/v1/auth/sign_in` en passant en paramètres JSON l'email et le mot de passe de l'agent. Par exemple (avec HTTPie) :

```httpie
http --json POST 'https://www.rdv-solidarites.fr/api/v1/auth/sign_in' \
  email='martine@demo.rdv-solidarites.fr' password='123456'
```

En cas de succès d'authentification, la réponse à cette requête contiendra dans le corps le détail de l'agent, et dans les headers les token d'accès à l'API. Par exemple :

```http
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Permitted-Cross-Domain-Policies: none
Referrer-Policy: strict-origin-when-cross-origin
Content-Type: application/json; charset=utf-8
access-token: SFYBngO55ImjD1HOcv-ivQ< token-type: Bearer
client: Z6EihQAY9NWsZByfZ47i_Q< expiry: 1605600758
uid: martine@demo.rdv-solidarites.fr
ETag: W/"0fe52663d6745c922160384e13afe1e1"
Cache-Control: max-age=0, private, must-revalidate
X-Meta-Request-Version: 0.7.2
X-Request-Id: 291fab6a-043b-4b9c-b4b9-3c7fc9c9453a
X-Runtime: 0.194743< Transfer-Encoding: chunked
* Connection #0 to host rdv-solidarites.fr left intact
{
  "data": {
    "id":1,
    "deleted_at":null,
    "email":"martine@demo.rdv-solidarites.fr",
    "provider":"email",
    "service_id":1,
    "role":"admin",
    "last_name":"VALIDAY",
    "first_name":"Martine",
    "uid":"martine@demo.rdv-solidarites.fr",
    "email_original":null,
    "allow_password_change":false
  }
}
* Closing connection 0
```

Les 3 headers essentiels pour l'authentification sont les suivants :

```http
access-token: SFYBngO55ImjD1HOcv-ivQ
client: Z6EihQAY9NWsZByfZ47i_Q
uid: martine@demo.rdv-solidarites.fr
```

- `access-token` : c'est le jeton d'accès qui vous a été attribué. Il a une durée de vie de 24h, après ça il vous faudra reproduire cette procédure pour en récupérer un nouveau.
- `client` : un identifiant unique associé à l'appareil depuis lequel vous avez effectué la requête
- `uid` : l'identifiant de l'agent dans l'API, égal à l'email de l'agent.

**Ces 3 headers doivent être transmis avec chacune de vos requêtes successives à l'API**, peu importe la méthode HTTP.

## Permissions

Les rôles et permissions des agents sont les mêmes via l'API que depuis l'interface web.

C'est à dire que les agents classiques ont accès à leur service uniquement, les agents du service secrétariat peuvent accéder aux agendas des agents des autres services, les agents admin ont accès à toute l'organisation, etc.

Par défaut, les requêtes en lecture n'appliquent aucun filtre et retourneront toutes les ressources auxquelles a accès l'agent connecté. Par exemple si un agent admin fait une requête pour accéder à la liste des absences sans filtre, l'API retournera toutes les absences de tous les agents appartenant aux organisations dont fait partie cet agent admin, ce qui peut faire beaucoup.

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
