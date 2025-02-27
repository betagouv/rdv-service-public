---
title: Diminution du nombre de connexions Postgres
date: 2025-02-24
status: approuvée
---

## Problème

<img width="775" alt="Un exemple d'incident d'effondrement de ram" src="https://github.com/user-attachments/assets/86df4529-e83a-4eb4-a95b-38bb1ec1c26f" />

On a eu plusieurs incidents pendant des mises en productions lors desquels on avait des "effondrements de RAM".
Après beaucoup de temps d'investigation par l'équipe SRE de Scalingo, et en interne chez nous, l'explication qui semble la plus plausible était qu'il y avait une contention mémoire lorsque les connexions de la nouvelle version de l'app sont ouvertes, et cette de l'ancienne ne sont pas fermées (et que l'OS met en cache dans la RAM les fichiers correspondant aux tables que Postgres lit fréquemment).
Ça arrive quand la nouvelle app répond aux requêtes, mais que l'ancienne ne s'est pas encore fermé.
A ce moment là, l'OS commence à swapper, et même si la mémoire est libérée sur les connexions qui sont fermées, il semble qu'il mette du temps à remettre en RAM la mémoire qui a été mise dans le disque.

Pour rappel :
- chaque connexion à postgres prend un peu de mémoire (je pense que c'est un petit process, similaire à un serveur web en fait), et quand on fait un déploy on ouvre plein de nouvelles connexions d'un coup
- le swap n'est pas parfait : quand il y a toutes ces connexions qui se créent, et toutes les autre qui se ferment, il y a quand même de la "contention mémoire", c'est à dire que l'os doit arbitrer qui garder en ram et qui swapper, et cet arbitrage peut mener à ce que les nouvelles connexions soient en swap même après que les anciennes ont libéré leur ram.

## Solution

Le nombre de connexions avait été augmenté dans https://github.com/betagouv/rdv-service-public/pull/4695
L'intention était d'éviter que les serveurs web attendent pour obtenir une connexion dans le cas où tous les thread d'un process sont en train de faire une requête, mais ce cas est très rare.

Au final, l'intérêt d'un connexion pool est de partager les connexions, pour avoir moins de connexions que de clients qui peuvent les utiliser. Ce n'est pas du tout ce qu'on fait actuellement, puisqu'on prévoit une connexion par thread, en plus des connexions partagées pour `load_async`.

Un grand merci à l'équipe Scalingo, qui nous a aidé à comprendre ce problème et à trouver une solution !

Autres fun facts qu'on a appris :
- Contrairement à mysql ou d'autres rdbms, Postgres ne charge pas les tables en mémoire, mais il compte sur l'os pour mettre en ram les fichiers des tables qui sont lus fréquemment. C'est à dire que l'OS met en ram des parties du disque (c'est un peu l'inverse du swap), pour que les lectures soient plus rapide (et les écritures aussi je crois).
- le graphe de mémoire de postgres affiché par scalingo montre la mémoire allouée par les process pg et par le cache en ram fait par l'os.
- peut-être que le nombre de connexions maximum proposé par Scalingo est un peu ambitieux sur le plan 8G 🤔
