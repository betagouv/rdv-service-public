# ProConnect

Pour tester ProConnect en local, il y a 2 possibilités :

1. utiliser les credentials de test de l’app de dev partagée
2. créer une nouvelle app de dev


## 1. utiliser les credentials de test de l’app de dev partagée

- Récupérer les clés secrètes de l’appli ProConnect de dev depuis Vaultwarden. L’entrée Vaultwarden s’appelle : « Fichier .env de développement local »
- Rappatrier les variables d’env dans votre .env local : `PRO_CONNECT_RDVSP_CLIENT_SECRET` et autres.
- Assurez vous d’avoir les variables d’env `PRO_CONNECT_BASE_URL` et `PRO_CONNECT_RDVSP_CLIENT_ID` (etc…) dans votre `.env` local. Si ce n’est pas le cas, recopiez les depuis `.env.sample`.
- Connectez vous depuis l’URL http://www.rdv-solidarites.localhost:3000/agents/sign_in


## 2. créer une nouvelle app de dev

Créer un compte avec votre mail beta sur https://partenaires.proconnect.gouv.fr

Puis créer un Fournisseur de service :

URLs de redirections post-connexion :
- http://www.rdv-mairie.localhost/agent_connect/callback
- https://www.rdv-mairie.localhost/agent_connect/callback

URL de redirections post-déconnexion :
- http://www.rdv-mairie.localhost/ (slash final important)
- https://www.rdv-mairie.localhost/ (slash final important)

⚠️ Important :

Algorithme de signature ID Token : ES256
Algorithme de signature user-info : ES256

Définissez les variables d’environnement en local :

- `PRO_CONNECT_BASE_URL="https://fca.integ01.dev-agentconnect.fr/api/v2"`
- `PRO_CONNECT_RDVSP_CLIENT_ID` et AN et S
- `PRO_CONNECT_RDVSP_CLIENT_SECRET` et AN et S

# FAQ

## Quels comptes peuvent être utilisés sur ProConnect en dev

Un compte pré-existant utilisable : `user@yopmail.com` : mot de passe `user@yopmail.com` a accès à de nombreuses organisations

Vous pouvez aussi utiliser n’importe quelle adresse mail à laquelle vous avez accès pour créer un nouveau compte.
Il faudra en effet valider la création du compte en recopiant un code de confirmation reçu par email.

cf https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/identifiants-fi-test

## Comment se déconnecter de ProConnect ?

Je ne sais pas 🤷
Ça serait pratique, notamment sur le domaine https://fca.integ01.dev-agentconnect.fr/

## Erreur __NSCFConstantString

Si vous rencontrez l’erreur suivante sur votre serveur Rails local lors du callback depuis ProConnect :

```
[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called
```

Vous pouvez démarrer votre serveur rails avec la var d’env suivante :

```
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES rails s
```

cf https://github.com/rails/rails/issues/38560
