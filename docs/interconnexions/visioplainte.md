# Visioplainte

## Historique et besoins exprimés

La Gendarmerie et la police nationale nous ont contacté en 2024 pour leur fournir une solution de prise de RDV en ligne pour le dépôt de plainte à distance.
Finalement, la police a décidé de ne pas utiliser les services de RDVSP.

Des discussions de spécification ont eu lieu.
Ils ne souhaitent pas faire passer les usagers par le site de RDVSP mais uniquement utiliser nos services via des API.
Il a été décidé de développer une API spécifique chez RDVSP pour leurs besoins.
On s’est mis d’accords sur cette API et le fichier [swagger a été défini](https://rdv.anct.gouv.fr/api-docs/index.html?urls.primaryName=Documentation%20API%20pour%20Visioplainte) puis implémenté peu à peu.

Le service de Visioplainte fonctionne en décidant d’un nombre de guichets ouverts a priori puis assigne les agents à ces guichets tardivement selon les RDV pris.
On a décidé de modéliser ça en créant des agents anonymes « Guichet 1 » qui ont des plages d’ouvertures.
Ces agents anonymes sont des « intervenants », c’est à dire des agents sans email.
Ils et elles ne peuvent donc pas se connecter à RDV Service Public.

Un autre besoin identifié est un environnement de staging pouvant être réinitialisé sur demande.

## Avancement

En date d’octobre 2024, nous avons fini de développer la première version de l’API.
Nous sommes en train de mettre en place l’environnement de staging.
Les équipes de SensioLabs nous indiquent travailler sur l’intégration de leur côté.

## Fonctionnement de l’API

L’API est implémenté par des contrôleurs tous regroupés dans `app/controllers/api/visioplainte`.
Les appels à notre API sont authentifiées via un header `X-VISIOPLAINTE-API-KEY`.
