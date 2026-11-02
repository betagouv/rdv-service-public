# Les statuts des RDV et des participants.

Le statut du RDV (status) est un statut général. **Il n'est pas représentatif des statuts individuels des usagers.**

**Chaque participant au RDV a son propre statut de participation porté par l'association `participations` du RDV.**

Pour les RDV avec l'attribut collectif à false les statuts du/des participants et du RDV seront tous identiques. (dans l'exemple suivant : `seen`)

Il est conseillé malgrés tout d'utiliser les statuts des participants (dans `participations`) quelque soit le type de rdv.

```rb
{
    "rdvs": [
    {
        "id": 8,
            "collectif": false,
            "status": "seen",
            "participations": [
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
                "participations": [
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
            "participations": [
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
            "participations": [
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
