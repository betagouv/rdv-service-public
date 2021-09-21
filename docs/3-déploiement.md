# Déploiement

RDV-Solidarités est hébergé chez [Scalingo](https://scalingo.com/fr/datacenters), sur la region Paris / SecNumCloud.

| Instance | domaine | branche | notes |
| -------- | ------- | ------- | ----- |
| production-rdv-solidarites | https://www.rdv-solidarites.fr | production | - |
| demo-rdv-solidarites | https://demo.rdv-solidarites.fr | production | - |
| recette-rdv-solidarites | https://recette.rdv-solidarites.fr | recette | review apps activées |


Pour permettre aux personnes référentes 

* d'être informer avant les mises en production ;
* de pouvoir tester les changements apportés ;

nous utilisons un mode de livraison hebdomadaire. Nous avons aussi une procédure d'urgence pour pouvoir apporter des modifications très rapidement en production. C'est une procédure exceptionnelle.

### Cas nominal

* L'équipe réalise une modification du service sur une **branche spécifique**. Cette modification est déployée sur un environnement de test très simple \(_review app_\) pour permettre à l'équipe de vérifier le bon fonctionnement des changements.
* Lorsque l'équipe pense que la modification du service correspond à ce qui a été défini, elle _merge_ les modifications dans une branche « recette ». Cette modification déployée sur l'environnement « recette » à l'adresse [https://recette.rdv-solidarites.fr](https://recette.rdv-solidarites.fr).
* Le mardi présentation des nouveautés, sur l'environnement de recette. Cet environnement est accessible aux référentes. Avec des données fictives. Les configuration et cas de test pourront être préservé d'une livraison à l'autre, un peu comme pour l'environnement de démo.
* Le jeudi, sauf demande particulière, nous faisons le « merge » la banche de recette sur la branche de production. Seul les éléments démontré le mardi seront mis en production. Nous allons utiliser un tag, le lundi soir ou mardi matin, avec la date pour signaler un point de livraison. La branche de production est automatiquement déployée sur l'environnement de production.

### Cas exceptionnel \(livraison rapide\)

* Développement sur une branche spécifique, avec déploiement sur un environnement spécifique \(review app\)
* Quand c'est ok, merge sur la branche « production » directement, déployé sur l'environnement « production »
* On rebase recette sur production pour mettre à jour la branche recette \(attention à préserver les commits de merge\)

### Notes

Les environnements de démo et de production son identique. La démo est une plateforme servant à découvrir le service ou à faire de la formation ou tester des configurations et scénario d'usage particulier.

La branche par défaut est « recette ».

Nous tenons à jour [les dernières nouveautés sur la doc](https://doc.rdv-solidarites.fr/dernieres-nouveautes). C'est lié à un répo [Github/rdv-solidarites/rdv-solidarites-doc](https://github.com/rdv-solidarites/rdv-solidarites-doc).

Les tickets de la colonne « En production » du [tableau de suivi des développements](https://github.com/betagouv/rdv-solidarites.fr/projects/8?fullscreen=true) après les avoir inscrit dans les dernières nouveautés.

