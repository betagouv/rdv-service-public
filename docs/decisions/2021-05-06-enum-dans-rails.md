---
title: Utiliser les `enum` de rails
date: 6 mai 2021
status: approuvée
---

## Contexte

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


## Décision

Pour simplifier et rendre le code cohérent, nous décidons aujourd'hui d'utiliser partout les Enums à la façon Rails.

Il reste effectivement un souci avec les Enum, la valeur en base de données est assez peu lisible [https://www.justinweiss.com/articles/creating-easy-readable-attributes-with-activerecord-enums/](https://www.justinweiss.com/articles/creating-easy-readable-attributes-with-activerecord-enums/)

Nous allons utiliser la gem [https://github.com/bibendi/activerecord-postgres\_enum](https://github.com/bibendi/activerecord-postgres_enum) pour utiliser les Enum PostgreSQL. Ça permettra d'avoir une information en base de donnée plus lisible.


