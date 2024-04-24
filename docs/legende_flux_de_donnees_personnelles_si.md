### Légende

- les flèches représentent un flux de données personnelles.
    Par exemple :
    - Background workers -> Brevo : indique que des données personnelles sont envoyées à Brevo depuis les background workers
    - Agents <-> Interface web : indique que les agents transactionnels des données personnelles à l'interface web, et lisent des données personnelles sur l'interface web.


- les rectangles représentent les processus qui n'ont pas de stockage persistant de données
- les cylindres représentent les stockages persistant


### Détails de chaque stockage

####

### DB Postgres

La base de données métier principale

Durée de conservation des données personnelles : jusqu'à 2 ans
Base légale de traitement : fonctionnement de l'application

### Redis

La base de données no-sql pour les données métiers et le cache

Durée de conservation des données personnelles : jusqu'à 7 jours
Base légale de traitement : fonctionnement de l'application

### Backups Postgres


### Informations complémentaires

L'équipe technique a accès à tous les stockage de données dans Scalingo à des fins de débuggage.



