# Liste des champs stockés dans la base de données

_Dernière mise à jour : 07/12/2020_

## Table absences

- Description
- Infos de récurrence
- Date de début
- Plage horaire
- Lien avec l'agent et l'organisation associés
- dates et heures de création et de dernière modification

## Table agents

- Email
- Email avant confirmation
- Mot de passe encrypté
- Jeton pour réinitialiser le mot de passe
- Jeton de confirmation
- Date et heure de la dernière réinitialisation de mot de passe
- Date et heure de confirmation
- Date et heure de l'envoi du mail de confirmation
- Role : Admin ou Agent
- Prénom
- Nom de famille
- Jeton d'invitation
- Date et heure d'invitation
- Date et heure d'acceptation
- Lien avec l'agent ayant invité
- Lien avec le service
- Date et heure de suppression
- Email avant suppression
- Jeton d'accès à l'API
- dates et heures de création et de dernière modification

## Table file_attentes

- Lien avec le RDV
- Lien avec l'usager
- Date et heure d'envoi des notifications
- Date et heure de l'envoi du dernier créneau trouvé
- Dates et heure de création et de dernière modification

## Table lieux

- Nom
- Lien avec l'organisation associée
- Dates et heures de création et de dernière modification
- Adresse
- Latitude
- Longitude

## Table motif_libelles

- Nom
- Lien avec le service
- Dates et heure de création et de dernière modification

## Table motifs

- Nom
- Couleur
- Durée par défaut
- Réservable en ligne : oui / non
- Délai minimum avant réservation
- Délai maximum avant réservation
- Lien avec le service
- Instructions avant la pose de RDV
- Instructions après la pose de RDV
- RDV réalisable par le secrétariat : oui / non
- Type de RDV : Sur place / a domicile / par téléphone
- RDV de suivi : oui / non
- Niveau de notifications
- Niveau de sectorisation : au département / à l'organisation / à l'agent
- Lien avec l'organisation associée
- dates et heures de création et de dernière modification
- Date et heure de suppression

## Table organisations

- Nom
- Département
- Horaires
- Numéro de téléphone
- Identifiant
- URL du site
- Email de contact
- dates et heures de création et de dernière modification

## Table plage_ouvertures

- Description
- Infos de récurrence
- Lien avec le lieu
- Lien avec l'agent associé

## Table rdv_events

- Type d'événement : notif SMS / notif mail
- Nom de l'événement : file_attente_creneaux_available / cancelled_by_agent / created ...
- Lien avec le RDV
- Date et heure de création

## Table rdvs

- Durée
- Date et heure de début
- dates et heures de création et de dernière modification
- Date et heure d'annulation
- Statut (cf États de rendez-vous)
- Adresse
- Créé par : agent / usager
- Notes libres de contexte
- Lien avec le(s) agent(s)
- Lien avec le(s) usager(s)
- Lien avec le motif
- Lien avec l'organisation associée
- Lien avec le lieu

## Table sector_attributions

- Lien avec le secteur
- Lien avec l'organisation associée
- Niveau d'attribution : à l'organisation / à l'agent
- Lien avec l'agent associé (optionnel)

## Table sectors

- Département
- Nom
- Identifiant
- Dates et heure de création et de dernière modification

## Table services

- Nom
- Nom court
- Dates et heure de création et de dernière modification

## Table super_admins

- Email
- Dates et heures de création et de dernière modification

## Table user_profiles (infos sur les usagers séparées par organisation)

- Type de logement : Sans domicile fixe / Hébergé / Locataire / En accession à la propriété / Propriétaire / Autre
- Notes libres des agents
- Lien avec l'organisation associée
- Lien avec l'usager

## Table users

- Prénom
- Nom de famille
- Nom de naissance
- Email
- Email avant confirmation
- Adresse
- Numéro de téléphone
- Date de naissance
- Lien avec l'agent ayant invité
- Caisse d'affiliation : CAF ou MSA
- Numéro d'allocataire
- Situation familiale
- Nombre d'enfants
- Lien avec l'agent référent
- Email avant suppression
- Mot de passe encrypté
- Date et heure de la dernière réinitialisation de mot de passe
- Date et heure du dernier envoi de mail de réinitialisation de mot de passe
- Jeton de confirmation
- Date et heure de la confirmation
- Jeton d'invitation
- Date et heure d'invitation
- Date et heure d'acceptation de l'invitation
- Date et heure de suppression
- phone_number_formatted
- dates et heures de création et de dernière modification

## Table webhook_endpoints

- URL du Webhook
- Secret partagé
- Lien avec l'organisation associée
- Dates et heure de création et de dernière modification

## Table zones

- Niveau de la zone : Rue / Commune
- Nom de la ville
- Code INSEE de la ville
- Lien avec le secteur
- Nom de la rue
- Code BAN de la rue
- Dates et heure de création et de dernière modification
