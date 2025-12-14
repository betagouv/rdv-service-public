# Cartographie de déploiement de la suite terrritoriale (ANCT)

Afin de valoriser l'implantation des produits de l'incubateur,
l'ANCT met en place une cartographie. Afin que RDV Service Public
apparaisse sur cette carte, nous devons implémenter une API.

Elle doit répondre aux critères décrits dans cette spec :
https://docs.numerique.gouv.fr/docs/6b33b32e-2f58-4179-8d1b-7c01414c44d3/

## Quelle données fournissons-nous ?

La spec nous indique de fournir pour chaque code SIRET et INSEE présent dans la base le
"Nombre total d'agents présents dans la base de donnée pour cette commune / collectivité".

Notre source de SIRET est le code SIRET fourni par ProConnect lors d'une connexion agent.
Notre source de code INSEE est les lieux physiques où les agents organisent les rendez-vous. 

Nous avons besoin d'inclure ces données pour les instances RDV-Solidarités et RDV-SP.
Nou faisons donc 4 requêtes à Metabse :
- Nombre d'agents par code INSEE (RDV-Solidarités)
- Nombre d'agents par code INSEE (RDV-SP)
- Nombre d'agents par SIRET (RDV-Solidarités)
- Nombre d'agents par SIRET (RDV-SP)

Nous fusionnons ensuite les résultats pour qu'ils soient conformes à l'exemple de la spec :

```json
{
  "count": 154,  // Total des résultats disponibles (hors pagination !)
  "results": [
   { "siret": "123425678901234", "metrics": {
     "tu": 1234, 
     "yau": 123, 
     "mau": 42, 
     "wau": 3 
   }},
   { "insee": "01001", "metrics": {
     "tu": 456,
     "yau": 112,
     "mau": 40,
     "wau": 17
   }},
   { "siren": "5678965430", "metrics": {
     "tu": 0,
     "yau": 0, 
     "mau": 0, 
     "wau": 0 
   }},
   { "insee": "75056", "metrics": {
     "tu": 150,
     "yau": 0, 
     "mau": 0, 
     "wau": 0 
   }}
 ]
}
```
