L'API de RDV Service Public permet à nos partenaires, comme par exemple Démarche Numérique et RDV Insertion, d'ajouter de la gestion de rendez-vous dans leurs applications métier.
Elle peut aussi être utilisée pour synchroniser les calendriers des agents de votre administration avec ceux qu'ils ont sur leur compte RDV Service Public.

L'API est disponible pour nos trois marques : RDV Service Public, RDV Solidarités, et RDV Aide Numérique.

Toutes les fonctionnalités de l'application ne sont pas encore disponibles via l’API. Contactez-nous si vous avez besoin de fonctionnalités qui ne sont pas encore présentes.

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

# Routes

Pour la version production, les requêtes doivent être adressées à https://www.rdv-solidarites.fr et non à https://rdv-solidarites.fr.

Pour la version démo, les requêtes doivent être adressées à https://demo.rdv-solidarites.fr.

# Authentification par OAuth 2.0

Presque tous les points de terminaison de l'API sont réservés aux agents authentifiés, dans la limite de leur rôle au sein de l'application.
Nous proposons uniquement l'authentification via le [protocole standard OAuth 2.0 (documentation en anglais)](https://oauth.net/2/).

Pour utiliser l’API via OAuth 2.0, voici les grandes étapes :
- [Nous contacter](https://rdv.anct.gouv.fr/aide/demande_support/new?role=agent&sujet=OAuth) en nous fournissant l'URI de redirection (`redirect_uri`) de votre application, c'est-à-dire l'URL vers laquelle l'agent sera renvoyé après son consentement
- Nous créons alors pour vous une application OAuth (appelée *client* dans la spécification OAuth 2.0) et nous vous envoyons ses identifiants : le `client_id` et le `client_secret`
  Attention, le `client_secret` ne vous est communiqué qu'une seule fois : conservez-le dans un gestionnaire de secrets
- Vous implémentez le flux *Authorization Code* (`grant_type=authorization_code`), le seul flux activé chez nous :
    - `GET/POST /oauth/authorize` — page d'autorisation : après consentement de l'agent, il est renvoyé vers votre `redirect_uri` avec un code d'autorisation (`code`)
    - `POST /oauth/token` — échange du code d'autorisation contre un jeton d'accès (`access_token`) et un `refresh_token`
      La requête doit être envoyée en `application/x-www-form-urlencoded` avec `grant_type=authorization_code`, `code`, `redirect_uri`, `client_id` et `client_secret`
    - `POST /oauth/revoke` — révocation d'un jeton
    - `GET /oauth/token/info` — informations sur le jeton présenté
- Vous appelez ensuite l'API en passant le jeton dans le header `Authorization: Bearer <access_token>`

Tous les jetons sont délivrés avec le scope `write`.

**À noter :**
Si vous avez surtout besoin d'être notifié des changements (création, modification, suppression de RDV, plages d'ouvertures, absences ou usagers), notre système de webhooks est plus adapté qu'un appel régulier à l'API : nous envoyons une notification HTTP POST vers votre service à chaque événement.
Voir la [documentation dédiée aux webhooks](https://github.com/betagouv/rdv-service-public/blob/production/docs/api/webhooks/api-notifications-webhooks.md).

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

# Dépréciations

**ATTENTION le champ `created_by` des `rdvs` et des `participations` est déprécié au profit du champ `created_by_type`.**

L'authentification via l'endpoint api/v1/auth/sign_in` en passant en paramètres JSON l'email et le mot de passe de l'agent est dépréciée en faveur de l'OAuth.


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

- `errors` : liste d'erreurs groupées par attribut problèmatique au format machine
- `error_messages` : idem mais dans un format plus facilement lisible.

# Principes fonctionnels

Dans le cadre des rendez-vous collectifs, chaque participation a un statut, qui peut etre différent de celui du rendez-vous.
Pour plus d'information, voir https://github.com/betagouv/rdv-service-public/blob/production/docs/api/v1/statuts.md.
