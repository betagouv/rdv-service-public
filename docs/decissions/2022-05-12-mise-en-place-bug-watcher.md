---
title: Mise en place d'un bug watcher
---

## Contexte

Nous avons accumulé beaucoup de ticket dans Sentry ;
Nous avons régulièrement des problèmes de perfs (certains ne sont d'ailleurs toujours pas résolu) ;
Nous recevons 3 ou 4 mails d'agents par jour.

Nous ne sommes pas organisé pour traiter rapidement ces points. Par traiter, nous pensons à 
- effectuer une rapide analyse pour vérifier le niveau de criticité ;
- faire un ticket dans le cas d'une résolution remise à plus tard ;
- faire un signalement à l'équpe dans le cas d'une résolution urgente à faire.

## Decision

Faire tourner un role de surveillant de bug (et de perfs).

L'idée serait de définir une personne qui pendant deux semaines serait LA personne en charge d'avoir à l'œil Sentry, Skylight, les mails et ticket sur Zammad.

Le rôle est tournant.
