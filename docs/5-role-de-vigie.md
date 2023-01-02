# Vigie

La vigie est un.e dev qui surveille la prod et qui traite les petites demandes au fil de l'eau pour permettre au reste de l'équipe d'être concentrée sur la roadmap et les sujets plus complexes.

C'est un rôle qui tourne toutes les 2 semaines dans l'équipe technique.


Un des deux buts de la vigie est de surveiller que tout se passe bien en prod pour que le reste de l'équipe tech puisse se concentrer sur son travail en toute sérénité. Ielle n'a pas forcément vocation à résoudre tous les bugs qui peuvent arriver, mais de surveiller la prod, notamment via Sentry.

L'autre but est de traiter les petites demandes (tout ce qui nécessite moins d'une journée de dev, ou les sujets où on sait clairement quelle est la petite amélioration à faire mais qu'on n'a jamais le temps de traiter). En traitant ces demandes rapidement à partir du moment où elles apparaissent, on limite la quantité de "petits sujets flottants" qui nous distraient.

On peut se permettre de dévier d'une organisation rigide et systématique : il arrive parfois que quelqu'un d'autre que la vigie soit capable de traiter un petit sujet plus efficacement, c'est pas grave si la vigie n'est pas la seule personne à traiter des petits sujets.

## Sentry

Sur Sentry, il faut filtrer sur les environnements pour avoir uniquement les erreurs de production. C'est possible à cette URL :https://sentry.incubateur.net/organizations/betagouv/issues/?environment=production&project=74

Afin d'avoir un usage efficace de Sentry, il est nécessaire de limiter le nombre d'issues non qualifiées, qui doivent être ré-examinées et ré-évaluées à chaque changement de vigie.

L'un des rôles de la vigie est donc de qualifier les issues Sentry :
- Si l'issue était temporaire et n'est plus active (ex: timeouts temporaires d'un service externe, couac d'un lancement de script ponctuel), on ignore "jusqu'à la prochaine occurrence".
- Si l'issue correspond à un bug / crash, on ouvre une issue GitHub dans laquelle on met un lien vers Sentry, et toutes les informations utiles à la résolution du problème. Afin de facilement s'y retrouver, on met l'URL de l'issue GitHub en commentaire dans l'issue Sentry.
- Si l'issue correspond à un comportement attendu de l'application (ex: erreurs 404), on peut choisir de l'ignorer avec un paramètre pertinent (ex: pas plus de 10 fois par semaine) laissé à l'appréciation de la vigie. ;)

*Note : actuellement, nous ne sommes pas parvenus à lier notre Sentry et notre GitHub, ce qui explique le côté fastidieux du second point.*

### Les erreurs ActiveRecord::NotFound

Il y a un volume d'erreur important lié à des ActiveRecord::NotFound, qui se traduisent souvent par des erreurs 404 pour les usagers.

Ces erreurs sont normalement ignorées au niveau du client Sentry (dans l'appli Rails), mais on a eu des cas où cela rendait des bugs invisibles (des mails qui ne s'envoyaient pas parce qu'on ne trouvait pas de lieux de rdv). On a donc réactivé ces erreurs sur le client Sentry, pour faire le tri au niveau du serveur Sentry (via l'appli web Sentry).

Ce qui nous intéresse, ce sont les erreur ActiveRecord::NotFound qui sont liée à un vrai bug et pas juste un lien obsolète. On peut donc trier sur la base de la présence du header http referer : les liens obsolètes qui sont partagés par mail ou conservés dans les favoris n'auront pas de valeur pour ce header, alors que les vraies erreurs, comme un lien cassé sur l'appli, auront notre nom de domaine dans le referer. On a ajouté la recherche sauvegardée "RecordNotFound with internal referer" dans Sentry pour chercher ce type d'erreurs.

Les erreurs liées à des liens obsolètes peuvent être ignorées avec des règles du type "Ignore until this occurs again 100 times per week". Le nombre exact d'occurrences par semaine est à trouver au cas par cas. Il vaut mieux commencer avec un nombre assez bas, et augmenter au fur et à mesure, ce qui nous permettra de voir s'il y a soudainement un pic d'erreurs de ce type (ce qui pourrait révéler un vrai bug, et pas juste un bruit de fond d'erreurs liées à des liens obsolètes).
