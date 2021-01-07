# INSTALL
## Prérequis

- Ruby 2.7.2 (nous conseillons l'utilisation de [Rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts))
- postgresql

## Développement

- Yarn : voir https://yarnpkg.com/en/docs/install
- Foreman : voir https://github.com/ddollar/foreman

## Initialisation de l'environnement de développement

Afin d'initialiser l'environnement de développement, exécutez la commande suivante :

```bash
bin/setup
```
Pour acceder à l'interface SuperAdmin créez un compte via la console Rails :

```
bundle exec rails console
SuperAdmin.create!(email: 'email_associated_to_your_github_account@prov.com')
```

## Lancement de l'application

```bash
foreman s -f Procfile.dev
```

L'application tourne à l'adresse [http://localhost:5000].


## Programmation des jobs

```bash
# Envoi des sms/email de rappel 48h avant le rdv
rake send_reminder

# Envoi des sms/email lorsque des créneaux se libèrent
rake file_attente

# Envoi d'un mail quotidien de monitoring des notifs a l'equipe
rake rdv_events_stats_mail
```
