---
title: Notre politique de mise à jour des gems (et libs JS)
date: 2023-02-24
status: proposition
---

## Contexte

Nos sommes en phase préparatoire d'un chantier sur l'homologation de nos pratiques de sécurité. C'est l'ANCT qui nous accompagne dans ce chantier.

Autre élément de contexte : notre service connait actuellement quelques perturbations, ce qui peut contribuer à dégrader notre relation avec nos partenaires et en particulier les départements du médico-social. Il est donc important pour nous d'éviter au maximum les perturbations de service.

## Objectif

L'un des points évoqué lors de l'homologation de sécurité est de définir une politique de mise à jour des librairies logicielles.

L'objectif de cet ADR est donc de définir une politique de MAJ des librairies en accord avec nos enjeux actuels.

## Décision

Voici les cas dans lesquels nous mettons à jour à jour une librairie spécifique :
- une version plus récente corrige une faille de sécurité (nous utilisons Dependabot pour être prévenu⋅es)
- une version plus récente permet de répondre à un besoin technique ou fonctionnel
- une montée de version est requises par une librairie correspondant aux critères ci-dessus (autrement dit, nous devons mettre à jour de manière indirecte)
- une fois par mois, nous mettons à jour les gems vers leur dernier "patch level", afin d'être proactif sur les fixes de sécurité et de bug
