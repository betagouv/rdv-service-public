# Interconnexions avec l’ANTS

L’ANTS (Agence Nationale des Titres Sécurisés) s’occupe des passeports et des cartes d’identités.
Un formulaire de pré-demande en ligne permet aux usager·es de remplir leur dossier de demande.
Un numéro de pré-demande en 10 caractères alphanumérique est remis à la fin de ce formulaire.

Suite à cette pré-demande, l'usager doit prendre rendez-vous en personne dans une mairie qui dispose d'un Dispositif de Recueil (DR),
un appareil qui permet de prendre les empreintes digitales.
Un site national permet de chercher un créneau pour prendre ce rendez-vous : [rendezvouspasseport.ants.gouv.fr](https://rendezvouspasseport.ants.gouv.fr)
Les usager·es peuvent prendre RDV dans n’importe quelle commune équipée d'un DR, peu importe leur commune de résidence, c'est le principe de déterritorialisation.

Lors des recherches, l’ANTS interroge les SI des mairies pour récupérer des créneaux disponibles pour ces rendez-vous.
Une fois le créneau sélectionné, l’usager·e est redirigé·e vers le site de prise de RDV de la mairie.
L’usager.e renseigne son numéro de pré-demande sur le site de prise de RDV de la mairie.

Un système de dédoublonnage des RDV est proposé par l’ANTS.
Le but est de réduire le nombre de créneaux réservés « en double ».
Par exemple un usager peut être tenté de réserver plusieurs créneaux dans plusieurs mairies, et il peut de surcroit oublier d’annuler les RDV futurs restants une fois qu’il aura effectué sa demande de dépôt.

Les deux mécanismes de recherche de créneaux et de dédoublonnage sont indépendants l’un de l’autre.

## Recherche de créneaux

Les éditeurs de logiciels agréés, dont RDV Service Public, déclarent 3 endpoints à l’ANTS :

- `getManagedMeetingPoints`
- `availableTimeSlots`
- `searchApplicationIds`

L’endpoint `getManagedMeetingPoints` est appelé régulièrement (plusieurs fois par jour) par l’ANTS et fournit en retour l’ensemble des lieux de RDV où des créneaux peuvent avoir lieu.
Pour chaque lieu, l’endpoint renvoie un nom, une commune et des coordonnées.

L’endpoint `availableTimeSlots` est appelé lors d’une recherche usager·e sur le site de l’ANTS.
L’ANTS envoie comme paramètres une plage de dates, un motif, un nombre de personnes souhaitant déposer un dossier, et des `meeting_point_ids`.
L’endpoint renvoie tous les créneaux disponibles dans ces lieux pour ces motifs.
L’ANTS applique un timeout de 15s sur ces requêtes.

Cette api est documentée [ici](https://ppd.api.rendezvouspasseport.ants.gouv.fr/docs#/API%20interfac%C3%A9es%20avec%20les%20%C3%A9diteurs/).

Tous ces endpoints sont définis par `Api::Ants::EditorController`.

### Authentification

L’ANTS authentifie ses requêtes vers nos endpoints via un token passé en header `X-HUB-RDV-AUTH-TOKEN`.

## Environnement de staging

L’ANTS fournit un environnement de staging - préproduction :

- Le site de recherche de créneaux [ppd.rendezvouspasseport.ants.gouv.fr](https://ppd.rendezvouspasseport.ants.gouv.fr/)

## Dédoublonnage

L’ANTS propose une base de données et des endpoints d’API pour le dédoublonnage des prises de RDV.
La documentation de l’API est disponible sur [api-coordination.rendezvouspasseport.ants.gouv.fr](https://api-coordination.rendezvouspasseport.ants.gouv.fr/docs#/).

Pour chaque `application_id` (= numéro de pré-demande), des `appointments` (créneaux réservés) peuvent être déclarés par les éditeurs de logiciel.
Un appointment est défini par le datetime de début du créneau, les infos du lieu de RDV et une `meeting_url` obligatoire où l’usager peut modifier et annuler son RDV.
Il semble y avoir une contrainte d’unicité sur la paire `application_id` - `meeting_url`

Chaque `application_id` a aussi un statut :

- `validated` : numéro validé par l’ANTS, des `appointments` peuvent être créés
- `consumed` : la demande a été déposée et reçue par l’ANTS, c’est elle qui passe le dossier à ce statut

Les éditeurs logiciels peuvent voir les appointments posés par d’autres éditeurs logiciels.


### Authentification

Nous nous authentifions à l’API de l’ANTS via un token passé en header et stocké dans une variable d’environnement : `ANTS_RDV_OPT_AUTH_TOKEN`.

### Environnement de développement

L’ANTS fournit un environnement de développement (aussi dit d’intégration) disponible sur [int.api-coordination.rendezvouspasseport.ants.gouv.fr](https://int.api-coordination.rendezvouspasseport.ants.gouv.fr)
Pour tester en local, renseignez les variables d’environnement suivantes :

```env
ANTS_RDV_OPT_AUTH_TOKEN=[récupérer dans vaultwarden]
ANTS_RDV_API_URL=https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api
```

Dans les seeds, la mairie de Sannois (95) est configurée pour ouvrir des créneaux de passeports.
Vous pouvez donc chercher et réserver un RDV en passant par [rdv-mairie.localhost:3000](http://www.rdv-mairie.localhost:3000)

Utilisez des application ID de tests, trouvés sur [cette issue GitLab](https://gitlab.com/france-titres/rendez-vous-mairie/interaction-avec-les-editeurs/-/issues/83#note_2154079306) :

status | application_id
-|-
validated | SOLOCAL001 à 5
declared | SOLOCAL004 à 6
consumed | SOLOCAL007 à 9
expired | SOLOCAL010 à 12

Pour vérifier simplement l’état dans la DB de l’ANTS : `rails runner 'puts AntsApi.status(application_id: "SOLOCAL002")'`

## Liens externes

- Le code de l’ANTS est [ouvert sur gitlab](https://gitlab.com/france-titres/rendez-vous-mairie/) et on peut ouvrir des issues auxquelles les développeurs·euses répondent rapidement.
- Ce [doc de conception d’Entr'ouvert](https://dev.entrouvert.org/projects/publik/wiki/Hub_Rdv_ANTS) décrit leur compréhension de l’API et leur solution envisagée
