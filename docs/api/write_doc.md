En cas de changement de la structure des réponses de l'API (changement dans les blueprints ou sur le format des attributs déjà présents) il faut tenir à jour la documentation Swagger et les tests associés.

Pour cela il faut modifier le fichier `swagger_helper.rb` en renseignant la nouvelle structure des données.
Exemple de l'ajout du model `MotifCategory` qui remplace l'enum `category` du model `Motif`

Avant :
On voit bien la propriété `category`

```ruby
{
  motif: {
    type: "object",
    properties: {
      id: { type: "integer" },
      category: { type: "string", enum: %w[rsa_orientation rsa_accompagnement rsa_orientation_on_phone_platform rsa_cer_signature rsa_insertion_offer rsa_follow_up] },
      deleted_at: { type: "string", nullable: true },
      location_type: { type: "string", enum: %w[public_office phone home] },
      name: { type: "string" },
      organisation_id: { type: "integer" },
      bookable_publicly: { type: "boolean" },
      service_id: { type: "integer" },
    },
    required: %w[id category deleted_at location_type name organisation_id bookable_publicly service_id],
  },
}
```

Après :
Ajout de la strucutre de donnée `motif_category` pour le model `MotifCategory` et sa collection `motif_categories`.

Suppression de l'enum `category` de `motif`.

J'ai fait apparaître l'objet `motif_category` dans la structure des objets `motif` en utilisant la syntaxe `"$ref" => "#/components/schemas/motif_category"`

```ruby
{
  motif: {
    type: "object",
    properties: {
      id: { type: "integer" },
      deleted_at: { type: "string", nullable: true },
      location_type: { type: "string", enum: %w[public_office phone home] },
      name: { type: "string" },
      organisation_id: { type: "integer" },
      motif_category: { "$ref" => "#/components/schemas/motif_category" },
      bookable_publicly: { type: "boolean" },
      service_id: { type: "integer" },
    },
    required: %w[id deleted_at location_type name organisation_id bookable_publicly service_id],
  },
  motif_categories: {
    type: "object",
    properties: {
      motif_categories: {
        type: "array",
        items: { "$ref" => "#/components/schemas/motif_category" },
      },
      meta: { "$ref" => "#/components/schemas/meta" },
    },
    required: %w[motif_categories meta],
  },
  motif_category: {
    type: "object",
    properties: {
      id: { type: "integer" },
      name: { type: "string" },
      short_name: { type: "string" },
    },
    required: %w[id name short_name],
  },
}
```


Pour chaque endpoint, utiliser [le DSL rswag](https://github.com/rswag/rswag) pour générer les points suivants dans la documentation :

- Description
- Format de données (JSON)
- Schéma d'authentification
- Schéma de données
- Paramètres de la requête
- Exemple de requête
- Exemple de réponse (header et body)
- Même processus pour chacune des erreurs qui peuvent être générées

Pour générer la documentation de l'API, utilisez la commande :

```sh
make rswag
```

Cette commande va regénérer le fichier api.json.
Pour générer cette documentation Swagger s'appuie sur les fichiers des factories.
Il faut donc s'assurer que tout est fonctionnel à ce niveau (ex : ne pas oublier une association)
