---
title: Processus de déploiement
date: jeudi 10 juin 2022
status: approuvée
---
       
## Contexte

Nous avons discuté et essayer une première fois de livre une fois par semaine (en 2021) avant de revenir à un mode de livraison au fil de l'eau.

Cette première tentative faisait suite à deux demandes :
- avoir un processus de recette un peu plus solide pour éviter les « problèmes » suite à une livraison
- faire en sorte que les référentes soient au courant avant les utilisateurs d'une modificaiton dans l'application (étant donnée qu'elles sont en charge du 1er niveau de support)

Nous avons eu du mal à nous tenir au processus, ce qui fait que nous avions souvent des livraisons qui passaient en direct avec les manipulations qui à la longue nous ont paru inutile.

À l'arrivé de Victor (début juin 2022), nous avons rediscuter de cela. Les référentes nous remontais encore des problèmes lié au décalage en livraison et information pour elle. Nous avons réduit les risques sur la qualité des livraisons, mais nous ne sommes pas à l'abri de problème.

Les notes de l'échange sont accessible [sur ce pad](https://pad.incubateur.net/CV_1ODVoTsmu8FEAG5wSOQ).

Le problème c'est encore posé ces derniers jours. Quelques changements important ont été mis en production alors que les référentes ne le savaient pas forcement. Le plus marquant a été le déplacement des invitations et gestion d'agent dans le module de configuration. Nous avons reçu beaucoup de message.

Nous avons également quelques difficulté avec les API. Par 2 fois nous avons mis en difficulté des partenaires en modifiant l'API sans les tenir informé.

## Objectif

Avoir un déploiement simple ;
Tenir informer les référentes avant la mise en production ;
Maintenir un haut niveau de qualité du logiciel.

## Decision

Nous allons préserver le déploiement continue. L'idée est de faire en sorte que ce soit un non évènement.

Nous avons opposé le déploiement par version (avec intégration continue) et le déploiement continue. Les librairies et autres outils ont besoin de maintenir plusieurs version en parallèle. **Dans notre cas, un service ne ligne, une seule version suffit. Alors pourquoi attendre pour livrer ?**

**Livrer par version fait que les modifications apportés au logiciel sont plus importante. Ce mode de livraison comportent donc plus de risque.**

**Les déploiements d'application de revue (Review app), lié au demande de changement (PR) reste un point clef pour s'assurer avant livraison que tout fonctionne correctement.**

2 points sont à améliorer :
- le soin lié aux changements dans les API
- la communication aux référentes.

Pour ce dernier point, nous convenons de « marquer » les PR devant faire l'objet d'une attention particulière quant à la communication avant déploiement. Le label utilisé sera « Nécessite une démo ». Il sera mis sur les PR qui ne devront surtout pas partir en production avant d'avoir bien communiqué aux référentes (démo, doc, lettre d'info, ...)

Discussion à avoir avec les personnes en charge de la lettre d'information : et si nous envoyons une lettre AVANT de mettre en production un gros changement ?

Un point rappelé également durant la discussion : la documentation, quelle soit lié à l'interface ou un changement dans l'interface, est très pertinante DANS l'interface. 

Par exemple, pour le déplacement de la gestion des agents, nous aurions pu laisser le menu quelques temps, avec une page expliquant le mouvement et les liens pour se rendre sur la nouvelle page.
