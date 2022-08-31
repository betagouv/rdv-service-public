# Vigie

La vigie est un rôle tournant dans l'équipe technique.
Le but de la vigie est de surveiller que tout se passe bien en prod pour que le reste de l'équipe tech puisse se concentrer sur son travail en toute sérénité. Ielle n'a pas forcément vocation à résoudre les bugs qui peuvent arriver, mais de surveiller la prod, notamment via Sentry.

Sur Sentry, on a les erreurs back-end visibles via la recherche sauvegardée "Ruby", et les erreurs de front via la recherche "Javascript". Il faut aussi filtrer sur les environnements pour avoir uniquement les erreurs de production.

Notre priorité est de comprendre et de résoudre les erreurs de back-end, et on peut ensuite se pencher sur les erreurs de front. Les erreurs de front sont plus souvent causées par des connections internet intermittente, et peuvent parfois être sans conséquences pour les usagers.

### Les erreurs ActiveRecord::NotFound

Il y a un volume d'erreur important lié à des ActiveRecord::NotFound, qui se traduisent souvent par des erreurs 404 pour les usagers.

Ces erreurs sont normalements ignorées au niveau du client Sentry (dans l'appli Rails), mais on a eu des cas où cela rendait des bugs invisibles (des mails qui ne s'envoyaient pas parce qu'on ne trouvait pas de lieux de rdv). On a donc réactivé ces erreurs sur le client Sentry, pour faire le tri au niveau du serveur Sentry (via l'appli web Sentry).

Ce qui nous intéresse, ce sont les erreur ActiveRecord::NotFound qui sont liée à un vrai bug et pas juste un lien obsolète. On peut donc trier sur la base de la présence du header http referer : les liens obsolètes qui sont partagés par mail ou conservés dans les favoris n'auront pas de valeur pour ce header, alors que les vraies erreurs, comme un lien cassé sur l'appli, auront notre nom de domaine dans le referer. On a ajouté la recherche sauvegardée "RecordNotFound with internal referer" dans Sentry pour chercher ce type d'erreurs.

Les erreurs liées à des liens obsolètes peuvent être ignorées avec des règles du type "Ignore until this occurs again 100 times per week". Le nombre exact d'occurrences par semaine est à trouver au cas par cas. Il vaut mieux commencer avec un nombre assez bas, et augmenter au fur et à mesure, ce qui nous permettra de voir s'il y a soudainement un pic d'erreurs de ce type (ce qui pourrait révéler un vrai bug, et pas juste un bruit de fond d'erreurs liées à des liens obsolètes).
