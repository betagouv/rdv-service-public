# Déploiement

RDV-Solidarités est hébergé chez [Scalingo](https://scalingo.com/fr/datacenters), sur la region Paris / SecNumCloud.

| Instance | domaine | branche | notes |
| -------- | ------- | ------- | ----- |
| production-rdv-solidarites | https://www.rdv-solidarites.fr | production | review apps activées |
| demo-rdv-solidarites | https://demo.rdv-solidarites.fr | production | - |

Les Pull Requests sont mises en production automatiquement dès qu’elles sont mergées sur la branche `production`.


### Cas nominal

Les changements qui ne demandent pas de démo ou de communication avec l’équipe des référentes sont mergées et mises en production directement. 
C’est le cas en principe des bugfixes, des refactor sans changement visible, des ajustements visuels, des tests, de la documentation…
⚠️ Dans les cas de refactor un peu importants, qui pourraient donc révéler des bugs en production, ou pour des migrations de données avec downtime, mieux vaut éviter de mettre en production en milieu de pic.
Nos utilisateurs ont des horaires de bureau: tactiquement, 12:30 et 18:15 sont les bons créneaux pour ce genre de mise en production à surveiller.  

### Démo aux référentes

Si la fonctionnalité est relativement importante, on peut faire une démo à l’équipe des référentes. Cet échange a deux buts:
* valider que le changement va bien dans le bon sens
* permettre aux référentes de prévenir les agents et d’ajuster les supports de formation.

La discussion sur ces fonctionnalités se fait sur les _review apps_, et a lieu en principe le mardi lors de la réunion hebdomadaire avec les référentes.

### Notes

Les environnements de démo et de production son identique. La démo est une plateforme servant à découvrir le service ou à faire de la formation ou tester des configurations et scénario d'usage particulier.

La branche par défaut est « production ».

Nous tenons à jour [les dernières nouveautés sur la doc](https://doc.rdv-solidarites.fr/dernieres-nouveautes). C'est lié à un répo [Github/rdv-solidarites/rdv-solidarites-doc](https://github.com/rdv-solidarites/rdv-solidarites-doc).

Les tickets de la colonne « En production » du [tableau de suivi des développements](https://github.com/betagouv/rdv-solidarites.fr/projects/8?fullscreen=true) après les avoir inscrit dans les dernières nouveautés.

