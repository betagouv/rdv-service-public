# Tech Tips

Quelques notes à propos de commandes, de scripts et autres bricoles qui nous aident.

## Console SuperAdmin

L’accès à /super_admins se fait:
* en `production` et en `development`, en OAuth via un compte GitHub
    * en `development`, le premier compte à tenter d’accéder est automatiquement ajouté.
* sur les review apps, en http Basic.
    * login: rdv-solidarites
    * password: défini automatiquement au déploiement (cf [scalingo.json](scalingo.json))
    * obtenu avec `scripts/review_app_super_admin_password.sh <numéro de la PR>`

## Schéma de données de la base

Il est possible de générer un diagramme de la base Postgres avec la commande :

```shell
make generate_db_diagram
```

Cela (re-)génère le fichier docs/domain_model.svg à partir de la base et des déclarations d'associations Rails.

Note : la librairie graphviz doit être installée ([voir guide](https://voormedia.github.io/rails-erd/install.html)).

## Tâches récurrentes

Nous utilisons la fonctionnalité de cron inclue dans GoodJob pour gérer nos tâches récurrentes.
Les jobs récurrents sont implémentés dans `app/jobs/cron_job.rb`.
Les horaires de ces jobs sont définis dans `config/initializers/good_job.rb`.

## Dumps de production

### Règles d'utilisation

Pour du débuggage ou des investigations sur la performance, il peut arriver aux membres de l'équipe de télécharger un dump de la production.

Cette opération est sensible, et doit donc toujours se faire en suivant ces règles :
- Supprimez le fichier zip du dump dès qu'il est chargé localement. Vérifiez qu'il est bien supprimé de la corbeille
- dès que vous avez fini votre investigation, supprimez la base de données et reprenez le seed avec les données factices.
- Pour éviter un oubli, ne gardez jamais un dump de production chargé en local pour plus de 48h.
- Faites attention à ce qu'il n'y ai pas de backup automatique de votre disque dur pendant que le dump de la db est dessus, que ça soit sous la forme de données en base, de fichier .pgsql, ou de fichier dans la corbeille.

Pour tester les migrations avec les données de prod, il faut récupérer un backup de la prod localement. Ça permet aussi de tester que nous arrivons bien à récupérer un backup valable de la production.

- `tar -xvzf <fichier-backup.tgz>` pour obtenir le fichier `.psql` ;
- `bundle exec rails db:drop db:create` ;
- `pg_restore -d development <fichier.pgsql>` ;

Il est recommandé de lancer le serveur local sans le worker sinon il y aura beaucoup de jobs de reminders et de simulations d'envois de mails :

`foreman start -f Procfile.dev  web=1,js=1`

## Export Excel sectorisation

> J’ai créé le secteur « Adour BAB Anglet rues » : vous serait-il possible de me faire une extraction excel de ce secteur uniquement svp ?

> Pour info la marche a suivre pour cet export :

```ruby
ruby scripts/scalingo_dump.rb -e production
rails runner scripts/export_sectors.rb 64
```

> Et la j’ai filtré a la main les lignes demandées.

## Liens utiles

- http://localhost:3000/letter_opener
- http://localhost:3000/rails/mailers
- http://localhost:3000/rails/info/routes
- http://localhost:3000/rails/info/properties


#### Tester une WebHook

- copier l’url que te donne `webhook.site` ;
- créer un endpoints, dans la page super admin > webhook, avec cette URL et n'importe quel secret ;
- déclencher des évènements en faisant des actions depuis l'interface _admin_ pour l'organisation associé ;
- les events apparaissent sur ta page webhook.site laissé ouverte.

## Tester les invitations

Pour le moment, il y a un système d'invitation avancé qui est utilisé par RDV-Insertion et qui n'est pas encore intégré dans RDV Service Public.

Le code qui génère le lien d'invitation dans le service de RDVI `Invitations::ComputeLink` dédié est présent dans ce fichier https://github.com/betagouv/rdv-insertion/blob/9c03e5a6c720a88826e84ca854fd5ccb6135569a/app/services/invitations/compute_link.rb#L2

Pour tester en local **depuis RDVSP** vous pouvez utiliser le script `scripts/invite_user.rb`.

## Montée en version des dépendances

### Version de Ruby
Pas de politique très clairement décidée mais la pratique est d’essayer de coller à la version la plus récente. Lors de la mise à jour de Ruby, il faut penser à mettre à jour la version cible de la gem `parser` dans le `Gemfile`, cf [le README de parser](https://github.com/whitequark/parser#compatibility-with-ruby-mri).

### Version de Rails
Pas de politique très clairement décidée mais la pratique est d’essayer de coller à la version la plus récente.

### Versions des gems et des node modules

Une politique de mise à jour prudente a été décidée
cf [l’ADR 2023-04-24](https://github.com/betagouv/rdv-service-public/blob/production/docs/decisions/2023-04-24-politique-maj-gems.md)

### Version du DSFR

1. `yarn upgrade @gouvfr/dsfr`. Notez le nouveau numéro de version, par exemple 1.13.0
2. Mettez à jour le lien symbolique vers les fichiers
   précompilés : `rm public/dsfr-v* && ln -s ../node_modules/@gouvfr/dsfr/dist/ public/dsfr-v1.13.0`
3. Mettez à jour la version dans `ApplicationHelper#dsfr_path`

Cette manière de faire permet d’éviter de passer par des compilations d’assets inutiles via webpacker ou sprockets.
Le numéro de version dans les chemins sert de fingerprint pour le cache bump des navigateurs.

### Version de Playwright

Playwright est notre système d’instrumentalisation du navigateur pour les tests E2E.
On utilise à la fois des gems et un package NPM, avec des contraintes de compatibilité entre les deux.
Il faut donc les mettre à jour simultanément. Un script permet de faire ça : `./scripts/update_playwright.sh`

## Review apps

Les review apps ne sont pas créées automatiquement pour chaque PR pour économiser des ressources.

La commande pour créer une review app pour la PR #4242 est

```bash
scalingo --region osc-secnum-fr1 --app rdv-service-public-review-app integration-link-manual-review-app 4242
```

Un raccourci existe pour retrouver le numéro de la PR correspondant à la branche courante automatiquement : `make review_app`

Par défaut, seul un worker web est activé, si vous souhaitez que les jobs s’exécutent il faut activer un worker jobs depuis le dashboard ou avec cette commande :

```sh
scalingo --region osc-secnum-fr1 --app rdv-service-public-review-app-pr4242 scale jobs:1
```

Le fichier `scalingo.json` décrit la configuration initiale et les variables d’environnement des review apps.
Les review apps sont détruites automatiquement à la fermeture de la PR ou après 48h sans déploiement.
On ne peut pas empêcher une PR spécifique d’être automatiquement détruite après ces 48h.
En revanche, on peut en recréer une nouvelle sans problème.

L’envoi d’email est désactivé par défaut sur les review apps.
Pour l’activer vous pouvez utiliser cette commande : `make enable_emails_on_review_app`


## Search Contexts

```mermaid
classDiagram
  WebSearchContext <|-- AgentPrescriptionSearchContext
  SearchContext <|-- WebSearchContext
  InvitationSearchContext <|-- WebInvitationSearchContext
  SearchContext <|-- InvitationSearchContext

  class SearchContext {
    - user
    - query_params
    + filter_motifs()
  }
```

## Metabase

Nous utilisons Metabase pour donner à l'ensemble de l'équipe une visibilité sur nos données.

Notre dossier d'architecture technique fournit une description haut niveau de notre usage de Metabase :
[architecture-technique.md](architecture-technique.md)

Le code qui gère notre pipeline d'ETL est disponible [ici](https://github.com/betagouv/rdv-service-public-etl)

### Mettre à jour Metabase

Nous avons utilisé le déploiement en un clic décrit dans cette doc de Scalingo :
https://doc.scalingo.com/platform/getting-started/getting-started-with-metabase

Pour mettre à jour Metabase il faut déclencher un deploy en utilisant la commande ci-dessous.

⚠️ Attention, une mise à jour de Metabase peut mal se passer et rendre notre Metabase indisponible.

```bash
scalingo --app rdv-service-public-metabase deploy https://github.com/Scalingo/metabase-scalingo/archive/refs/heads/master.tar.gz
```

## Debug des feature specs

Une manière pratique et intéractive d’écrire ou de debugger des feature specs (end-to-end) est :

- insérer un `debugger` dans la spec avant la ligne qui échoue
- préfixer `HEADLESS=false` avant l’appel à `bundle exec rspec ...`
- le test utilisera alors le driver capybara JS même si le flag `js: true` n’est pas présent
- le navigateur Chrome orchestré par Capybara sera maintenant visible

Une console s’ouvre alors et on peut appeler des commandes comme `click_button "Enregistrer"` ou bien rédiger des `expect` itérativement. On peut sortir de la console et laisser le test terminer son éxecution avec CTRL+D.

Ça ne fonctionne pas avec `byebug` ou un breakpoint de debug sur RubyMine, lorsqu’on éxecute une commande dans la console ouverte, le navigateur semble bloqué.
Je suppose que l’éxecution du serveur Rails de spec est complètement interrompue, ce qui n’est pas pratique pour itérer

## Nombre maximum de threads et de connexions en production

### Nombre max de connexions ouvertes à la base de données PostgreSQL

Le tableau ci-dessous présente le nombre de connexions maximum à la base de données PostgreSQL pouvant être ouverts.
Il s’agit des chiffres pour l’instance historique RDV Solidarités.

|                                      | web | jobs | variables d’env | où trouver la config ? |
|------------------------------------- | --- | ---- | --------------- | ---------------------- |
| scalingo_workers_count               | 8   | 2    | -               | `scalingo scale`       |
| processes_per_worker                 | 3   | 1    | WEB_CONCURRENCY | config/puma.rb         |
| connection_pools_sizes_per_worker    | 4   | 8    | GOOD_JOB_MAX_THREADS et RAILS_MAX_THREADS | config/database.yml |
| extra_connections_per_process        | 0   | 3    | -               | doc de GoodJob         |
| total_max_connections                | 96  | 22   | -               | -                      |

Soit un total de 118 connexions à la base PostgreSQL ouvertes simultanées possibles.

### Nombre max de threads ruby

Le tableau ci-dessous présente le nombre de threads maximum pouvant être ouverts simultanémment.
Il s’agit des chiffres pour l’instance historique RDV Solidarités.

|                               | web | jobs |
|-------------------------------|-----|------|
| scalingo_workers_count        | 8   | 2    |
| processes_per_worker          | 3   | 1    |
| max_threads_count_per_process | 4   | 5    |
| total_max_threads             | 96  | 10   |

Aujourd’hui, le nombre de threads ruby web et de connexions à la DB ouvertes possibles est le même. Ce n’est pas strictement nécessaire, on pourrait baisser le nombre max de connexions ouvertes.

