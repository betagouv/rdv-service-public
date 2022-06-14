---
title: Garder la doc technique dans le dépôt applicatif
date: 2022-06-13
status: approuvée
---

## Contexte

L'arrivé récente (entre 1 et 3 mois) de plusieurs devs dans l'équipe a changé les modes de travail. Par le passé, il y avait juste 2 devs et donc le contexte était partagé au quotidien de manière informelle. L'agrandissement de l'équipe nous pousse donc à :
- étoffer la documentation de nos pratiques et de notre culture technique
- tenir assidument un log des décisions techniques afin d'avoir un historique du contexte et des raisons de chaque décision

### Fichiers `.md` dans `docs/`

Jusqu'à maintenant la doc se trouve dans le [repo applicatif](https://github.com/betagouv/rdv-solidarites.fr), dans le répertoire `docs/`. L'un des inconvénients d'avoir cette solution est que les modifications à la doc doivent passer le même workflow de validation que les modifications applicatives (passage par une Pull Request, verification par les pairs) et déclenche une mise en production une fois la proposition mergée.

### Migration vers un wiki GitHub ?
La semaine du 6 juin 2022, François F. a tenté de migrer la doc vers un Wiki GitHub. Certains inconvénients ont été rencontrés : difficultés à faire des liens vers d'autres pages, pas de support pour les [front matters](https://jekyllrb.com/docs/front-matter/), pas de fonctionnalité de sommaire / listing de pages, pas de gestion de l'arborescence des répertoires (tous les fichiers sont "en vrac"). La somme de ces difficultés rendent l'usage du wiki GitHub incompatible avec une édition markdown locale, "à la Jekyll", qui semble correspondre davantage à la culture de l'équipe.

## Objectif

Afin que la doc soit complète, vivante et à jour, il est important qu'elle soit :
- facile à trouver, rechercher, facile à parcourir
- rapidement éditable afin d'inciter à participer


## Décision

Bien que la présence de la doc technique dans `docs/` présente des inconvénients (lourdeur de workflow), ils semble largement contrebalancés par les avantages (liberté de format, édition locale).

Il a donc été décidé de garder la doc technique dans `docs/`.
