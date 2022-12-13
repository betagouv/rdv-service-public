---
title: Migrer vers le Sentry mutualisé de l'incubateur beta
date: 2022-12-12
status: approuvée
---

## Contexte

RDV Solidarités / RDV Aide Numérique manipule des données de santé et des données personnelles. Jusqu'ici nous utilisions Sentry en version Saas (sentry.io), avec une configuration qui ne fait pas remonter les paramètres des requêtes afin de limiter au maximum les risques de présence de données personnelles.

Nous avons eu des discussions autour de la possibilité de faire remonter ces params afin de faciliter le débuggage. Nous avons conclu qu'il n'était pas possible de savoir à l'avance si un paramètre pouvait contenir une donnée sensible, et donc nous avons décidé de continuer à ne pas remonter les params.

Néanmoins, nous remontons quelques données potentiellement personnelles, comme les adresses e-mail des usagers si ils rencontrent une erreur lorsqu'ils sont connectés. Nous avons donc jugé judicieux de quitter la version SaaS (actuellement hébergée en Iowa, USA) au profit de la version mutualisée proposée par l'incubateur beta aux startups. Cette version mutualisée a été lancée en mars / avril 2022 (il y a 8 mois) et est hébergés par empreintedigitale.fr sur une hébergement certifié HDS et ISO27001.

## Objectif

Cesser d'envoyer des données potentiellement personnelles aux USA, mais plutôt utiliser une instance mutualisée d'un outil open source, gérée par beta.

## Décision

Au cours de la semaine du 12 décembre 2022, nous ferons pointer le DSN Sentry de la production vers l'instance beta de Sentry.

Nous ne ferons pas de migration de données d'un Sentry à l'autre car il n'y a pas de moyen simple de le faire.

Pendant quelques semaines / mois, nous continuerons de consulter l'ancien Sentry à titre d'archive en lecture seule. Les liens Sentry présents dans les issues GitHub devrons être mis à jour au fil de l'eau si possible.
