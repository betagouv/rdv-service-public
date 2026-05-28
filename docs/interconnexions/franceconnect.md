# FranceConnect

## Identité des sub

FranceConnect ne supporte QUE l'identifier type `pairwise`

Les FI doivent renvoyer des `sub` différents pour un même usager mais pour 2 FS différents.
Le mécanisme de `sector_identification_uri` permet de palier à ça et de demander à FranceConnect de renvoyer les mêmes subs pour plusieurs FS.
C'est le domaine de cette URL qui est utilisé comme salt des sub.

On a configuré cette valeur sur nos FS cf https://github.com/betagouv/rdv-service-public/pull/5492

## Liste des FS

Les client ID sont publics, on peut les voir dans l'URL vers laquelle on est redirigés lorsqu'on clique sur le bouton FranceConnect.

Petit script pour récupérer le client ID du FS FranceConnect d'un de nos domaines :

```sh
DOMAIN=demo.rdv-solidarites.fr bundle exec rails runner "puts URI.decode_www_form(URI(Faraday.get(\"https://#{ENV['DOMAIN']}/franceconnect_v2/auth\").headers['location']).query).to_h['client_id']"
```
