---
title: Mise en place d'une vigie
date: 12 mai 2022
status: approuvée
---

## Contexte

Nous avons accumulé beaucoup de tickets dans Sentry ;
Nous avons régulièrement des problèmes de perfs (certains ne sont d'ailleurs toujours pas résolu) ;
Nous recevons 3 ou 4 mails d'agents par jour.

Nous ne sommes pas organisé pour traiter rapidement ces points.

Auparavent l'équipe était petite et stable. Il y a beaucoup de nouvelles arrivées dans l'équipe, et des changements encore à venir.

Les personnes de l'équipe tech se sente parfois déborder par le volume de travail (bugs, features, ...)

## Objectif

Apporter de la sérénité à celles et ceux qui n'ont pas le rôle à ce moment là.
Avoir une personne qui est très vigilante sur les bugs.

**Améliorer la qualité de l'application**

## Decision

Mettre en place une vigie pour avoir l'œil sur les bugs et les perfs.
Le rôle est tournant sur 2 semaine.

Les tâches à effectuer en tant que vigie sont :
- effectuer une rapide analyse pour vérifier le niveau de criticité ;
- faire un ticket dans le cas d'une résolution remise à plus tard ;
- faire un signalement à l'équpe dans le cas d'une résolution urgente à faire.

| | Très grave | Un peu embettant | Pas grave |
| - | ---------- | ---------------- | --------- |
| Facile | Rollback + Fix Résolution | Résolution | Ticket Github ou résolution |
| Difficile | Rollback + Ticket github |  Ticket github | Ignorer avec commentaire |

Grave : ~ 10 % des utilisateurs ne peuvent plus utiliser l'application. S'il y a plus de 2 personnes qui remonte le même problème dans la même journée, c'est sans doute grave.
Un peu embettant : l'utilisation de l'application est dégradé, mais on s'en sort avec des contournements ou des disfonctionnement non bloquant.
Pas grave : l'application est utilisable.

**La vigie n'a pas à corriger tout les bugs et problème de perfs !**

Rendre visible qui est vigie quand sur l'[agenda RDV-Solidarité](https://cloud.rdv-solidarites.fr/index.php/apps/calendar/p/5oC3oimECzNZGten)

Prévoir qu'une personne qui arrive qui arrive dans l'équipe tech prend le prochain tour de vigie et décale les autres.

