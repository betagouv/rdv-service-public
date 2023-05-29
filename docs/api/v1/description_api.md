L'API de RDV-Solidarités vous permet de lire des données dans notre base depuis votre logiciel.

Toutes les fonctionnalités de RDV-Solidarités ne sont pas encore disponibles via l’API. Contactez-nous si vous avez besoin de fonctionnalités qui ne sont pas encore présentes.

# Requêtes

L'API adhère aux principes REST :

- requêtes `GET` : lecture sans modification
- requêtes `POST` : création de nouvelle ressource
- requêtes `PATCH` : mise à jour d'une ressource existante
- requêtes `DELETE` : suppression d'une ressource

Les paramètres des requêtes `GET` doivent être envoyés via les query string de la requête.

Les paramètres des requêtes `POST` doivent être transmis dans le corps de la requête sous un format JSON valide, et doivent contenir le header `Content-Type: application/json`.

Les paramètres doivent respecter les formats suivants :
- `DATE` : "YYYY-MM-DD" par exemple : "2021-10-21"
- `TIME` : H:m[:s], par exemple : "10:30"

# Versionnage

L'API est versionnée. La version actuelle est 1.0 (référencée comme v1 dans les points de terminaison).

# Routes

Les points de terminaison de l'API sont accessibles par une route de la forme : `https://<domain>/api/<version>/<endpoint>`.

Avec :

- `version` est la version de l'API
- `endpoint` est le nom du point de terminaison

Par exemple, on aura : `https://<domain>/api/v1/absences`

Pour la version production, les requêtes doivent être adressées à https://www.rdv-solidarites.fr et non à https://rdv-solidarites.fr.

Pour la version démo, les requêtes doivent être adressées à https://demo.rdv-solidarites.fr.

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
    "email":"martine@demo.rdv-solidarites.fr",
    "provider":"email",
    "service_id":1,
    "role":"admin",
    "last_name":"VALIDAY",
    "first_name":"Martine",
    "uid":"martine@demo.rdv-solidarites.fr",
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



# Sérialisation

L'API supporte uniquement le format JSON. Toutes les réponses envoyées par l'API contiendront le header `Content-Type: application/json` et leur contenu est présent dans le body dans un format JSON à désérialiser.

# Pagination des réponses par listes

Tous les points de terminaison qui retournent des listes sont paginés. De manière générale, tout point de terminaison qui retourne une liste peut retourner une liste vide.

## Paramètres

Le paramètre (optionnel) `page` permet d'accéder à une page donnée. Sauf précision contraire dans la documentation d'un point de terminaison donné, on retrouve 100 éléments par page.

## Résultats

La réponse contient en outre un objet meta qui indique le nombre total de pages et d’items, par exemple :

```rb
{
  […],
  "meta": {
      "current_page": 1,
      "total_count": 112,
      "total_pages": 2
  }
}
```

# Rate limiting

L'utilisation de l'API est limitée pour les points de terminaison sans authentification. Vous pouvez effectuer au maximum 50 appels par minutes. Si vous dépassez cette limite, une erreur 429 vous sera renvoyée et vous trouverez le temps que vous devez attendre avant de relancer une requête dans le header (`Retry-After`).

# Codes de retour

L'API est susceptible de retourner les codes suivants :

| Code  | Nom                   | Description                                                                   |
| ----  | --------              | --------                                                                      |
| `200` | Success               | Succès                                                                        |
| `204` | No Content            | Succès mais la réponse ne contient pas de données (exemple : suppression)     |
| `400` | Bad Request           | La requête est invalide                                                       |
| `401` | Unauthorized          | L'authentification a échoué                                                   |
| `403` | Forbidden             | Droits insuffisants pour réaliser l'action demandée                           |
| `404` | Not Found             | La ressource est introuvable                                                  |
| `422` | Unprocessable Entity  | La donnée transmise est mal formattée                                         |
| `429` | Too Many Requests     | Trop de requêtes ont été effectuées                                           |
| `500` | Internal Server Error | Une erreur serveur produite (l'équipe technique est notifiée automatiquement) |

# Erreurs

En cas d'erreur reconnue par le système (par exemple erreur 422), les champs suivants seront présents dans la réponse pour vous informer sur les problèmes :

- `errors` : [ERREUR] : liste d'erreurs groupées par attribut problèmatique au format machine
- `error_messages` : [ERREUR] : idem mais dans un format plus facilement lisible.

# Principes fonctionnels

- Les statuts des RDV et des participants.

Le statut du RDV (status) est un statut général. **Il n'est pas représentatif des statuts individuels des usagers.**

**Chaque participant au RDV a son propre statut de participation porté par l'association `rdvs_users` du RDV.**

Pour les RDV avec l'attribut collectif à false les statuts du/des participants et du RDV seront tous identiques. (dans l'exemple suivant : `seen`)

Il est conseillé malgrés tout d'utiliser les statuts des participants (dans `rdvs_users`) quelque soit le type de rdv.

```rb
{
  "rdvs": [
    {
      "id": 8,
      "collectif": false,
      "status": "seen",
      "rdvs_users": [
        {
          "id": 8,
          "status": "seen",
          "user": {
            "id": 10,
            "first_name": "Tristan",
            "last_name": "LEROUX",
          }
        },
        {
          "id": 9,
          "status": "seen",
          "user": {
            "id": 11,
            "first_name": "Marie",
            "last_name": "LEROUX",
          }
        }
      ],
      "users_count": 2,
    }
  ],
}
```

Pour les RDV avec l'attribut collectif à true les statuts du/des participants peuvent être différents.

Ici, le RDV a un status `seen` mais les 3 participants ont des status de participation différents.
- Tristan Leroux s'est présenté au RDV collectif : `seen`
- Roger Lapin ne s'est pas présenté et n'a pas annulé : `noshow`
- Marie Dupont a annulé sa venue : `excused`

`users_count` représente le nombre d'inscrits au RDV en temps réél (Tous les statuts hors `revoked` et `excused`)

```rb
{
  "rdvs": [
    {
      "id": 8,
      "collectif": true,
      "status": "seen",
      "rdvs_users": [
        {
          "id": 8,
          "status": "seen",
          "user": {
            "id": 10,
            "first_name": "Tristan",
            "last_name": "LEROUX",
          }
        },
        {
          "id": 9,
          "status": "noshow",
          "user": {
            "id": 11,
            "first_name": "Roger",
            "last_name": "LAPIN",
          }
        },
        {
          "id": 7,
          "status": "excused",
          "user": {
            "id": 12,
            "first_name": "Marie",
            "last_name": "DUPONT",
          }
        },
      ],
      "users_count": 2,
    }
  ],
}
```
