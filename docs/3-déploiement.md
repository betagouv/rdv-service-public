# Déploiement

RDV-Solidarités est hébergé chez [Scalingo](https://scalingo.com/fr/datacenters), sur la region Paris / SecNumCloud.

| Instance | domaine | branche |
| -------- | ------- | ------- |
| production-rdv-solidarites | https://www.rdv-solidarites.fr | production |
| demo-rdv-solidarites | https://demo.rdv-solidarites.fr | production |

Les Pull Requests sont mises en production automatiquement dès qu’elles sont mergées sur la branche `production`.


### Cas nominal

Les changements ayant un impact sur l’usage du service doivent être montrés en démo aux référentes pour les tenir informées et vérifier qu’il n'y a pas de veto avant d'être mis en production.
Les autres changements peuvent partir en production directement. C’est le cas en principe des bugfixes, des refactor sans changement visible, des ajustements visuels, des tests, de la documentation…

⚠️ Dans les cas de refactor un peu importants, qui pourraient donc révéler des bugs en production, ou pour des migrations de données avec downtime, mieux vaut éviter de mettre en production en milieu de pic.

Nos utilisateurs ont des horaires de bureau: tactiquement, 12:30 et 18:15 sont les bons créneaux pour ce genre de mise en production à surveiller.

### Démo aux référent·es

Si la fonctionnalité est relativement importante, on peut faire une démo à l’équipe des référent·es. Cet échange a deux buts :
* valider que le changement va bien dans le bon sens
* permettre aux référent·es de prévenir les agents et d’ajuster les supports de formation.

La discussion sur ces fonctionnalités se fait sur les _review apps_, et a lieu en principe le mardi lors de la réunion hebdomadaire avec les référent·es.

### Notes

Les environnements de démo et de production sont identiques. La démo est une plateforme servant à découvrir le service ou à faire de la formation ou tester des configurations et scénario d'usage particulier.

La branche par défaut est `production`.

