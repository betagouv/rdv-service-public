---
title: Utiliser des « fausses » suppressions
date: 24 novembre 2022
status: approuvée
---


Des décisions ont été prises sans être documenté.
Ce document est donc une docuemntation à postériori.

Aujourd'hui, nous ne supprimons pas vraiment les `rdv`, `user`, `agent` et `motif`.

_Dans cette liste il manque les `lieu`, une issue à été créé pour remédier à ce
manque : https://github.com/betagouv/rdv-solidarites.fr/issues/3130_


## Pourquoi nous ne supprimons pas ces objets ?

L'historique des RDV est utilisé pour faire les statistiques. Il faut garder 2
ans de RDV pour les exports et les statistiques.

Les usagers, les agents, les motifs (et les lieux) sont lié au RDV. S'ils sont
lié à un RDV et que nous les supprimons, les RDV lié ne pourront plus être
affichés.

Il y a aussi un aspect « preuve », « trace ». Mais l'utilisation de PaperTrail
sur ces objets nous permet de couvrir ce besoin (bien que nous ne l'utilisions
pas trop dans ce sens pour le moment).

## Pourquoi on souhaite supprime ces objets ?

Les utilisateurs ne veulent plus voir ces objets parce que 
- un agent peut partir, quitté la structure, changer de service
- un motif n'est plus utilisé
- un lieu a fermé
- un usager à déménager (autre cas ?)


## Le soft delete coûte cher

L'élément déclencheur de ce besoin de documentation c'est le nombre d'erreurs
dans le sentry ces derniers jours à propos d'usager supprimé (qui sont en fait
« doucement » supprimé)

Il y a aussi eu une erreur qui a bloqué l'envoie de toutes les notifications de
rappel.


Ces erreurs sont apparus lorsque nous avons mis en place, à l'instar de ce que
nous avions fait sur les RDV, un `default_scope` pour filtrer les usagers « par
défaut » (et donc arrêter d'essayer d'utiliser partout un scope `.active`. Voir
la PR https://github.com/betagouv/rdv-solidarites.fr/pull/3028.


Il y a des avis divers et variés dans la littérature des internets à propos de
l'utilisation du `default_scope`. Il y a une question de confiance entre ce
qu'on dit aux utilisateurs et ce qu'on fait vraiment.

L'utilisation du `default_scope` peut poser question, mais là, nous sommes dans
un cas où ça semble logique de l'utilisé.

_Il serait pertinent de le mettre en place pour chaque objet, pour avoir une
cohérence et surtout réduire les risques d'afficher des objets alors qu'en fait
ils devraient être supprimés_


## Les autres pistes

Pour maintenir les statistiques, nous pourrions prendre d'autres voies plutôt
que d'utiliser le `soft_delete`

### Dénormalisation

Figer les RDV passés : insérer dans le RDV les informations nécessaire de
l'usager, l'agent et du lieu, sans jointure vers les tables correspndantes.

Nous pourrions le faire dans une novuelle table (pour le pas polluer celle des
RDV à venir).

Ou bien nous pourrions également dénormaliser les RDV à venir. **Le problème
sera de mettre en place un mécanisme permettant de mettre à jour les RDV**.
Lorsqu'un lieu, un motif, un agent ou un usager est mis à jour, il faudrait
retrouver les RDV à venir (les passées ne nous intéressent pas dans ce cas)
pour modifier les contenues copiés dedans.

Ça nécessite de maintenir une liste des RDV (à venir uniquement) lié à un lieu.
Une sorte de table de jointure, mais depuis l'extérieure...

### Supprimer un RDV après la suppression d'un User

Si on supprime un usager, est-ce qu'il faut aussi supprimer tout ces RDV ? Cela
pourrait résoudre notre problème actuel (où nous n'arrivons plus à afficher un
RDV parce que l'usager à été « supprimé doucement », mais que le
`default_scope` ne nous permet pas de le voir.

Mais les départements souhaitent maintenir l'historique de RDV, y compris pour
un usager « supprimé » (à revérifier)

## Décision

Structuré sans le `soft_delete` n'est peut-être pas si évidant.

Si l'on reviens au problème qui déclenche cette réfléxion : 

Le `default_scope` ajouté dans l'objet `User` génère des erreurs 500 lorsque
nous affichons un RDV (non supprimé) dont l'usager à été « supprimé doucement
».

Même problème pour l'envoie des rappels de notifications.

Il serait nécessaire de pouvoir préciser des situations où désactiver le
`default_scope`.

Cette PR c'est occupé de mettre cela en place :
https://github.com/betagouv/rdv-solidarites.fr/pull/3110/files

