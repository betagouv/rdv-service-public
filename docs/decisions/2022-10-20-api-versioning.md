---
title: Expression de la version de l'API
date: 2022-10-20
status: approuvée
---

## Contexte

À ce stade l'API contient deux dimensions :
- une première, bien établie, est consommée par des clients et nécessite leur authentification : `/api/v1/`
- une seconde, plus récente, vient d'être mise en production et est également consommée par des clients mais ne nécessite pas d'authentification : `/public_api/`

D'autres points de terminaison vont rapidement voir le jour et venir enrichir cette API sans authentification.

Dans ce cadre de changements autour de l'API, on s'interroge sur la bonne manière de la versionner.

## Objectif

Définir la façon dont on versionne l'API.

## Options envisagées

Plusieurs options sont possibles pour que le client détermine la version de l'API qu'il appelle :
- la mettre dans la route
- la passer dans un header
- la passer en paramètre

## Décisions

On convient que la version doit apparaître dans la route, car :
- c'est un élément déterminant, du point de vue du client, et à ce titre c'est important d'être très explicite
- l'API authentifiée exprime déjà la version dans la route et, s'il serait possible de changer ce comportement à partir d'une `v2`, les routes déjà existantes préfixées par `/api/v1/` ne pourront potentiellement jamais changer
- c'est aussi une convention bien établie et partagée

On remarque au passage que l'API sans authentification n'exprime pas sa version (`/public_api/`). On peut même considérer qu'elle n'est pas versionnée. Toutefois, elle ne contient qu'un seul endpoint (`public_links`). Les nouveaux endpoints de cette partie peuvent être préfixés par `/api/v1/`, `public_links` devenant une sorte d'exception qu'il ne sera possible de supprimer que le jour où plus aucun client ne s'en sert.
