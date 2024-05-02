## Légende du diagramme de flux de données personnelles dans le SI

[Voir le diagramme](/docs/flux_de_donnees_personnelles_si.svg)

- Les flèches représentent un flux de données personnelles.  Par exemple :
    - Background workers -> Brevo : indique que des données personnelles sont envoyées à Brevo depuis les background workers
    - Agents <-> Interface web : indique que les agents transmettent des données personnelles à l'interface web, et lisent des données personnelles sur l'interface web.
- Les cylindres représentent les stockages persistant (bases de données, stockages de fichiers, etc...)
- Les rectangles représentent les processus qui n'ont pas de stockage persistant de données (serveurs webs, jobs cron, etc...)

On affiche ici une seule des applications métier Scalingo, mais le schéma est le même pour les trois (osc-secnum-fr1/production-rdv-solidarites, osc-secnum-fr1/production-rdv-mairie, osc-secnum-fr1/demo-rdv-solidarites).

## Détails de chaque stockage

### DB Postgres

La base de données métier principale

- Durée de conservation des données personnelles : jusqu'à 2 ans
- Justification du traitement : fonctionnement de l'application

### Redis

La base de données no-sql pour certaines données métiers et le cache

- Durée de conservation des données personnelles : jusqu'à 7 jours
- Justification du traitement : fonctionnement de l'application

### Logs applicatifs

Les logs de l'application, qui indiquent chaque requête http (journalisation), conservés dans l'infrastructure Scalingo.
Voir https://www.cnil.fr/fr/la-cnil-publie-une-recommandation-relative-aux-mesures-de-journalisation,

- Durée de conservation des données personnelles : 1 an. voir https://doc.scalingo.com/platform/app/logs#log-retention
- Justification du traitement : débuggage, traçabilité des accès si nécessaire, surveillance du bon fonctionnement de l'application

### Backups Postgres

Des dumps périodiques de la base de données principale faits automatiquement par Scalingo, ou lancés manuellement par l'équipe technique. Voir https://doc.scalingo.com/databases/postgresql/backing-up#retention-policy-for-periodic-backups
Leur usage est encadrés conformément à notre documentation : https://github.com/betagouv/rdv-service-public/blob/production/docs/4-notes-techniques.md#r%C3%A8gles-dutilisation

- Durée de conservation des données personnelles: jusqu'à 12 mois pour les backups automatiques, ❌ pas de date d'expiration automatique pour les backups manuels
- Justification du traitement : débuggage, investigations sur les performances, et le cas échéant rétablissement du servie après incident majeur

### DB Postgres d'ETL

Une base de données dans laquel on télécharge un dump de la production, qu'on anonymise immédiatement avant de le rendre accessible depuis notre metabase (le metabase n'a donc jamais accès à des données personnelles)

- Durée de conservation des données personnelles: le temps nécessaire à l'exécution du script d'anonymisation, environ 2 heures.
- Justification du traitement : investigations sur l'usage du produit

### SI des partenaires

On envoie des informations sur les rdv par des webhooks, et les SI de nos partenaires peuvent utiliser notre API pour consulter et écrire des données métier.

- Durée de conservation des données personnelles: ❌ à clarifier
- Justification du traitement : ❌ à clarifier

### Sentry

Serveur de monitoring d'erreur hébergé par la Dinum à l'adresse https://sentry.incubateur.net. Données personnelles accessibles uniquement par l'équipe technique.

- Durée de conservation des données personnelles: 3 mois
- Justification du traitement : Débuggage et support

### Brevo

Envoi d'emails transactionnels, notamment pour les confirmations et rappels de RDV. Accessibles aux membres de l'équipe betagouv.

- Durée de conservation des données personnelles: 6 mois (voir https://app-smtp.brevo.com/retention-logs)
- Justification du traitement : fonctionnement de l'application et support utilisateurs

### Link Mobility (anciennement Netsize)

Envoi de sms transactionnels notamment pour les confirmations et rappels de RDV.

- Durée de conservation des données personnelles: ❌ à clarifier
- Justification du traitement : fonctionnement de l'application et support utilisateurs

### SFR Mail2SMS

Envoi de sms transactionnels pour les conseils départementaux des Hauts-de-Seine et du Pas-de-Calais

- Durée de conservation des données personnelles: ❌ à clarifier
- Justification du traitement : fonctionnement de l'application

### Clever Technologies

Envoi de sms transactionnels pour le conseil départemental de la Seine-et-Marne

- Durée de conservation des données personnelles: ❌ à clarifier
- Justification du traitement : fonctionnement de l'application

### Informations complémentaires

L'équipe technique a accès à tous les stockage de données dans Scalingo à des fins de débuggage.

