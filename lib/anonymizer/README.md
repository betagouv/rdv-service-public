# Anonymizer

Cette gem permet de supprimer des données personnelles d'une base de données, dans le but de la rendre disponible à un outil de Business Intelligence, par exemple Metabase.

## Publication d'une nouvelle version de la gem

TODO: il faudrait renommer la gem en sql-anonymizer, car le nom `anonymizer` est déjà pris.
```
gem build anonymizer.gemspec
gem push anonymizer-*.gem
```

## Fonctionnalités

### Suppression des données personnelles

Anonymizer écrase les données personnelles des colonnes que vous voulez anonymiser. C'est donc un outil à utiliser seulement sur des copies de votre base de données, et surtout pas sur une base de données de production.

### Exhaustivité

Cette gem permet de vérifier de manière exhaustive que des règles d'anonymisation ont été définies pour toutes les colonnes d'une base.
Cette vérification peut être ajoutée à la CI de votre projet pour vous assurer de ne pas oublier de définir les règles pour les nouvelles colonnes ajoutée à votre base.

## Outils similaires

[PostgreSQL Anonymizer](https://postgresql-anonymizer.readthedocs.io/) est une autre solution pour anonymiser une base de données Postgres, avec d'autres parti pris techniques, et plus de fonctionnalités.
