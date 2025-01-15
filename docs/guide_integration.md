# Guide d'intégration de RDV Service Public avec des applications tierces

Ce guide s'adresse aux équipes technique et produit qui développent des outils utilisés par les agents de la fonction publique.

Vous pouvez ajouter un bouton "Prendre rendez-vous" dans votre application métier qui permettra à vos agents de planifier un rendez-vous avec des usagers.

Ce bouton déclenchera une connexion par OAuth avec RDV Service Public, puis redirigera l'agent vers un formulaire de prise de rendez-vous.

## Implémentation

### Connexion OAuth

La connexion OAuth vous permettra d'obtenir un token d'api pour faire des appels au nom de l'agent qui utilise votre outil.

Elle passe par les endpoints `https://demo.rdv.anct.gouv.fr/oauth/authorize` et `https://demo.rdv.anct.gouv.fr/oauth/token` lors du développement.

Contactez notre équipe technique à l'adresse support@rdv-service-public.fr pour demander la création d'une appli OAuth et préparer votre intégration.

### Prise de rendez-vous

Après avoir obtenu un token d'accès à l'api, vous pouvez faire un appel à l'api de création de "RDV Plan", qui permet de créer un brouillon de rendez-vous.

Exemple :
```
POST /api/v1/rdv_plans
{
    "user": {
        "id": 123
        "first_name": "Francis", // obligatoire
        "last_name": "Factice", // obligatoire
        "email": "francis.factice@gmail.com",
        "phone_number": "0611223344",
        "address": "21 rue des Ardennes, 75019 Paris",
        "birth_date": "1990-12-31"
    },
    "return_url": "https://monsuivisocial.incubateur.anct.gouv.fr/callback/123",
    "dossier_url": "https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123" // sera affiché sur la page de détail du rdv et la
}
```

Seuls les champs `user.first_name` et `user.last_name` sont obligatoires, les autres sont facultatifs.

Vous obtiendrez une réponse à ce format :
```
{
    "rdv_plan": {
        "id": 23,
        "rdv": null,
        "user_id": 345,
        "url": "http://demo.anct.gouv.fr/agents/rdv_plans/23/edit_starts_at"
    }
}
```

Vous pouvez ensuite rediriger votre agent à l'url indiquée pour qu'il prenne le rendez-vous.

Après ce premier appel, vous pouvez faire des requêtes sur le RDV Plan pour savoir si le rendez-vous associé a été crée: `GET /api/v1/rdv_plans/23`.
