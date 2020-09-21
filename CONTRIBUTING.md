# CONTRIBUTING


## Objectifs

- Mettre en prod aussi fréquemment que possible et d'autant petites releases que possible
- Limiter le stock des "En cours" pour éviter d'avoir trop de sujets en tête en même temps
- Chaque développeur·se doit pouvoir être autonome dans le processus de déploiement

## Dévelopement

### Processus de dev, qualité etc

- Lint via rubocop. automatisé sur la CI
- Obligation de review des PRs pour merger.
- Découpage des grosses PRs en plusieurs petites. Utilisation du feature flipper pour cacher la feature sur les envs non-dev

### Processus de développement

- Choisir une tâche dans la colonne `Backlog produit`, la déplacer dans `Développement en cours`, se l'assigner
- Une fois le code développé, créer une PR, attendre la review, ajouter le tag `à examiner` sur trello.
- Une fois la PR approuvée :
- Merger la PR. Cela déclenche le déploiement en démo et en production
- Une fois le déploiement terminé avec succès, déplacer la tâche vers `En production et en démo`.

### Vues

- préférer le passage explicites de variables locales à l'utilisation de variables d'instances venant des controlleurs dans les partials pour permettre plus de généricité

## Tests

- Privilégier les tests unitaires sur les tests bout en bout ;
- Nous allons considérer que les tests unitaires dans rails peuvent inclure ActiveRecord ;
- Chaque élément nécessaire à un test doit se trouver dans un même écran (dans les mêmes ~20 lignes);
- Nous utilisons [RSpec](https://rspec.info/) pour écrire nos tests


## Déploiement

Les environnements de production et de pré-production (démo) sont hébergés sur
[Scalingo](https://scalingo.com/)

La CI est configurée pour déployer automatiquement la branche `master` vers un
un environnement de [démo](https://demo.rdv-solidarites.fr) et **vers la production**.


> _Note : Éviter de merger des PR simultanément_
>
> Il faut éviter de merger sur master des PRs trop rapprochées (quelques minutes) pour éviter que ça ne s'emmêle et déploie la mauvaise
> 
> ou alors, il faut merger la première PR -> annuler le build CircleCI tout de suite -> puis merger la deuxième PR


### Déploiement manuel (vers la demo ou la production)

`scalingo integration-link-manual-deploy -a demo-rdv-solidarites master`

Pré-requis :
- être ajouté en tant que collaborateur sur l'application Scalingo, demandez à un membre de l'équipe
- Installer le [CLI Scalingo](https://doc.scalingo.com/platform/cli/start)
- Connectez votre machine avec `scalingo login --api-token SOME_TOKEN` que vous pourrez créer ici : [https://my.scalingo.com/profile](https://my.scalingo.com/profile)


