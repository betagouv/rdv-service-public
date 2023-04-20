# Dossier technique

__IMPORTANT: DOSSIER A COMPLETER EN EDITANT TOUTES LES PARTIES `!!<>!!`__

> Ce dossier a pour but de présenter l’architecture technique du SI. Il n’est par conséquent ni un dossier d’installation, ni un dossier d’exploitation ou un dossier de spécifications fonctionnelles.


**Nom du projet :** !!<nom du projet>!!

**Dépôt de code :** !!<URL du dépôt de cote>!!

**Hébergeur :** !!<Nom hebergeur - Localisation - Region>!!

**Décision d’homologation :** !!<date>!!

**France Relance :**  !!<✅/❌>!!

**Inclusion numérique :** !!<✅/❌>!!

## Suivi du document

> Le suivi de ce document est assure par le versionnage Git.

## Fiche de contrôle

> Cette fiche a pour vocation de lister l’ensemble des acteurs du projet ainsi que leur rôle dans la rédaction de ce dossier.

| Organisme | Nom | Rôle | Activité |
|----|----|----|----|
| !!<nom de l’organisme>!! | !!<nom prénom de la personne>!! | Lead tech | !!<Rédaction/Relecture>!! |
| !!<nom de l’organisme>!! | !!<nom prénom de la personne>!! | Développeur | !!<Rédaction/Relecture>!! |
| !!<nom de l’organisme>!! | !!<nom prénom de la personne>!! | Product Manager | !!<Rédaction/Relecture>!! |
| !!<nom de l’organisme>!! | !!<nom prénom de la personne>!! | Charge de porte-feuille  | !!<Rédaction/Relecture>!! |
| Incubateur des territoires | Charles Capelli | Consultant SSI | Relecture |

## Description du projet

!!<Description du projet en quelques lignes>!!

## Architecture

### Stack technique

!!<Détailler la stack technique du projet par service en abordant les motivations de ces choix>!!

### Matrice des flux

| Source | Destination | Protocole | Port | Localisation | Interne/URL Externe |
|----|----|----|----|----|----|
| *!!<Front>!!* | *!!<API>!!* | *!!<HTTPS>!!* | *!!<443>!!* | *!!<Cluster X Namespace Y>!!* | *!!<Interne>!!* |
| *!!<API>!!* | *!!<Base de données>!!* | *!!<TCP>!!* | *!!<5432>!!* | *!!<Cluster X Namespace Y>!!* | *!!<Interne>!!* |
| *!!<Front>!!* | *!!<API lambda>!!* | *<!!HTTPS>!!* | *!!<443>!!* | *!!<France - OVH>!!* | *!!<https://api.lambda.fr>!!* |

### Inventaire des dépendances

| Nom de l’applicatif | Service | Version | Commentaires |
|----|----|----|----|
| !!<Site web>!! | !!<Nginx>!! | `<1.0.0>` | Build depuis une stack Elm + Vite |
| !!<API>!! | !!<NodeJS>!! | `<16>` | Framework HTTP `Koa.js` && ORM `TypeORM` |
| !!<Base de données>!! | !!<PostgreSQL>!! | `<3.1>` | Operateur CrunchyData |

### Schéma de l’architecture

!!<Ajouter un graphe sur l’architecture du SI et de ses relations avec les services externes, vous pouvez utiliser notre instance Kroki pour cela:!! [!!https://kroki.incubateur.anct.gouv.fr/!!](https://kroki.incubateur.anct.gouv.fr/)!!. Les formats DITAA, BlockDiag ou UML conviennent pour cet exercice>!!

### Schéma des données

!!<Ajouter un graphe de votre modèle de données, vous pouvez utiliser le format ERD de l’instance Kroki pour cela>!!

## Exigences générales

### Accès aux serveurs et sécurité des échanges

!!<Détailler en quelques lignes la façon dont vous administrer le SI et quelles mesures de sécurité vous avez mis en place pour cela>!!

### Authentification, contrôle d’accès, habilitations et profils

!!<Détailler en quelques lignes le processus d’authentification et la façon dont les accès sont restreints>!!

### Traçabilité des erreurs et des actions utilisateurs

!!<Détailler en quelques lignes la façon dont vous reportez les erreurs et les logs>!!

### Politique de mise à jour des applicatifs

!!<Détailler en quelques lignes votre politique de mise a jour des dépendances de votre SI>!!

### Intégrité

!!<Quels contrôles avez vous mis en place pour détecter des problèmes d’intégrité du SI et qu’avez vous mis en place pour vous en prémunir (monitoring, backups, etc)>!!

### Confidentialité

!!<Avez-vous un besoin accru en confidentialité et si oui, qu’avez vous mis en place>!!
