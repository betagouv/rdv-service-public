# FranceConnect

## Setup en local

Pour tester FranceConnect en local, il y a 2 possibilités :

1. utiliser les credentials de test des apps FS bac à sable partagées
2. créer des nouvelles apps FS bac à sable

### 1. utiliser les credentials de test des apps FS bac à sable partagées

- Récupérer toutes les clés secrètes des applis FS bac à sable FranceConnect de dev depuis Vaultwarden.
  L’entrée Vaultwarden s’appelle : «  FranceConnect v2 (local) - tous domaines - .env ».
- Connectez vous par exemple depuis l’URL http://www.rdv-solidarites.localhost:3000/users/sign_in (⚠️ http + localhost + port)

### 2. créer une nouvelle app FS bac à sable

Créer une app par domaine depuis ici : https://espace.partenaires.franceconnect.gouv.fr/

Il faut créer une app par domaine local car FranceConnect n'accepte qu'un domaine commun pour toutes les URL de callback et logout, contrairement à ProConnect.

⚠️ Dans les champs « URL du Site » et « URL d'identification de secteurs » il faut mettre des URL publiquement accessibles.

Par exemple :

|champ|valeur|
|-|-|
| Nom de l'instance | http://www.rdv-etat.localhost:3000 |
| URL du site | https://rdv.numerique.gouv.fr/users/sign_in |
| URL(s) de redirection de connexion | http://www.rdv-etat.localhost:3000/franceconnect_v2/callback |
| URL(s) de redirection de déconnexion | http://www.rdv-etat.localhost:3000/franceconnect_v2/post_logout |
| Algo | ES256 |

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
