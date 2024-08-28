# Authentification

L'authentification à l'api se fait en passant la clé d'api dans le header `X-VISIOPLAINTE-API-KEY`.

Par exemple:
```
curl --request GET --url "https://demo.rdv.anct.gouv.fr/api/visioplainte/creneaux" --header "X-VISIOPLAINTE-API-KEY: LA_CLE_D_API"
```
