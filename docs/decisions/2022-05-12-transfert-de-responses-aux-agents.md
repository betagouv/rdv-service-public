---
title: Transferer les réponses usagers directement aux agents concernés
date: 12 mai 2022
status: approuvée
---


## Contexte

- Nous envoyons des emails de notification aux usagers ;
- Nous ne souhaitons pas exposer l'adresse email des agents ;
- Nous utilisons une adresse `contact@rdv-solidarites.fr` et `support@rdv-solidarites.fr` pour l'envoie et la réponse à ces emails ;
- Certains usagers répondents aux emails de notification pensant dialoguer avec l'agent avec qui il ou elle avait RDV ;
- L'équipe de support transfert les emails aux agents concernés le plus rapidement possible, mais parfois un peu en retard ;


## Objectif

Faire en sorte que les réponses usagers partent directement dans les boites mails des agents concernés.


## Décision

### Comment router les mails reçus à rdv+***@reply.rdv-solidarites.fr ?

Deux options s'offrent à nous :

- créer une boite mail chez Gandi, et faire du polling dessus pour récupérer les nouveaux mails, puis les traiter.
- utiliser un service externe qui permet que tous les e-mails envoyés à un sous-domaine soient détectés et transmis en HTTP à notre appli

La solution retenue pour le moment est la seconde, à travers le système proposé par Sendinblue (qui est le seul non américain à proposer ce service, et qui se trouve être déjà notre outil d'envoi de mails transactionnels). Ce choix nous a paru le plus simple, mais rien ne nous empêchera de changer à l'avenir.

J'ai testé l'envoi de mails depuis mes adresses perso vers le domaine @reply.rdv-solidarites.fr avec un webhook en place qui transmet à une URL de test proposée par webhook.site.

Note : les webhooks Sendinblue de type "inbound" n’apparaissent pas dans leur interface web, mais sont bien listés via leur API (il faut bien demander les webhooks de type inbound et non transactional).

### Où stocker le token ?

Afin de pouvoir retrouver un RDV à partir de l'e-mail de réponse, il fallait stocker un identifiant dans la base et faire en sorte de le joindre au mail de réponse, en utilisant une adresse du type rdv+UUID@reply.rdv-solidarites.fr.

Il était possible de stocker le token dans :

    un Rdv
    un RdvsUser
    un Receipt

J'ai fait le choix de stocker le token dans Rdv pour le moment, principalement car les mailers n'ont pas accès aux RdvsUsers et au Receipts, et qu'il était donc difficile de générer l'adresse de ReplyTo depuis les mailers.

Je me suis aussi dit que si une personne était ajoutée par erreur à un RDV puis supprimée juste ensuite, elle allait recevoir un mail de notification pour la création, et il était alors préférable qu'elle puisse répondre, ce qui aurait été impossible si le token était stocké dans un RdvsUser.

Je me dis aussi que si on change d'avis (par exemple stocker le token dans les Receipts), la migration sera simple.

### Sous quel format transmettre le contenu de la réponse ?

Lorsque l'usagè⋅re répond au mail de notification, son client mail va faire en sorte de citer le mail original et de permettre de répondre au dessus de cette citation. Cette citation ne nous intéresse pas, ou du moins nous ne souhaitons pas la faire apparaître lorsque nous notifions l'agent de la réponse.

La bonne nouvelle, c'est que Sendinblue nous fournit dans son payload une version Markdown du mail, dans laquelle ils ont déjà exclu la citation. C'est donc ce champ (ExtractedMarkdownMessage) que nous allons utiliser pour transmettre la réponse.


