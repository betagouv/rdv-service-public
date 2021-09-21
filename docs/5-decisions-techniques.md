# Décisions techniques

## 2021-05-20 Moins de code

Pour faciliter la maintenance de l'application en restant une équipe de petite taille, nous devons réduire le volume de code.

Nous pensons qu'il y a trop de chose pour la construction de l'interface graphique. Nous souhaitons réduire l'usage du JavaScript, supprimer Bootstrap, et supprimer Webpack pour revenir à un asset-pipeline plus basique.

## 2021-05-06 Sérialiser les configurations des fournisseurs d'envoi de SMS

Aujourd'hui,  la prise en charge du cout de l'envoi de SMS est réparti de la même manière pour tous les départements. Nous allons permettre à chaque département d'avoir son propre fournisseur d'envoi de SMS.

Pour y arriver, il faut ouvrir le paramétrage vers d'autres fournisseurs. Aujourd'hui, nous savons envoyer des SMS avec NetSize et SendInBlue. Chacun de ces fournisseurs utilise sont propre système d'envoi de SMS, et du coup, une configuration spécifique.

Nous aurions pu utiliser une table spécifique pour chaque fournisseur, en créant une relation polymorphique dessus depuis le territoire.

Nous préférons utiliser la sérialisation en JSON. Ajout d'une colonne pour connaitre le fournisseur \(et donc quel programme exécuter pour l'envoi de message et pour savoir comment sérialiser/désérialiser le JSON\), et une colonne JSON contenant la configuration sérialisée. N'ayant pas de requête à faire dessus, cela semble pertinent pour offrir la flexibilité nécessaire.



## 2021-05-06 Enum dans rails

Il existe dans l'application deux façons de gérer les Enums. 

La façon apportée par Rails depuis la version 5 \(?\)

```ruby
enum status: { unknown: 0, waiting: 1, seen: 2, excused: 3, notexcused: 4 }
```

Et la version plus ancienne en ruby

```ruby
SECTORISATION_LEVEL_AGENT = "agent".freeze
SECTORISATION_LEVEL_ORGANISATION = "organisation".freeze
SECTORISATION_LEVEL_DEPARTEMENT = "departement".freeze
SECTORISATION_TYPES = [SECTORISATION_LEVEL_AGENT, SECTORISATION_LEVEL_ORGANISATION, SECTORISATION_LEVEL_DEPARTEMENT].freeze
```

Pour simplifier et rendre le code cohérent, nous décidons aujourd'hui d'utiliser partout les Enums à la façon Rails.

Il reste effectivement un souci avec les Enum, la valeur en base de données est assez peu lisible [https://www.justinweiss.com/articles/creating-easy-readable-attributes-with-activerecord-enums/](https://www.justinweiss.com/articles/creating-easy-readable-attributes-with-activerecord-enums/)

Nous allons utiliser la gem [https://github.com/bibendi/activerecord-postgres\_enum](https://github.com/bibendi/activerecord-postgres_enum) pour utiliser les Enum PostgreSQL. Ça permettra d'avoir une information en base de donnée plus lisible.

## 2020-03-16 Vox Usager

_La date est approximative, je ne sais pas quand cette décision a été prise_

Aucun moyen de récolter le feedback utilisateur \(usager\). À moins d'aller faire des tests utilisateurs sur site, ou de regarder le Matomo.

L'idée est d'utiliser VOX Usager pour la récole de feedback usage

Nous décidons de mettre en place un lien vers vox-usager pour récolter du feedback



