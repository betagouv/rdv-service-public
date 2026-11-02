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

# Authentification par OAuth

Presque tous les points de terminaison sont réservés aux agents authentifiés, dans la limite de leur rôle au sein de l'application.
Le mode d'authentification recommandé est via le protocole d'OAuth 2.0. Vous pouvez contacter notre équipe technique via le formulaire de contact de l'application pour demander la création d'une application OAuth.

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
