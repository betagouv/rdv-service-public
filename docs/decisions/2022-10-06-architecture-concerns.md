---
title: Exploration d'une architecture de capacité par les concerns
date: 2022-10-06
status: approuvée
---

## Contexte

Des actions de contrôleurs, pour réaliser des opérations métier, utilisent des _form objects_, qui utilisent eux-même des _service objects_.
Des validations sont effectuées dans les _form objects_, d'autres dans le modèle lui-même.
D'autres contrôles, ainsi que des opérations métier, sont effectuées séquentiellement dans les _service objects_.

Il en résulte que certaines parties de la base de code sont jugées peu claires.
Leur ajouter un nouveau comportement, ou une nouvelle validation, nécessite d'avantage d'efforts.

## Objectif

Clairifier l'architecture de l'application afin d'augmenter sa maintenabilité et de faciliter l'arrivée de nouveaux membres dans l'équipe.

## Solution proposée

Une piste possible est l'ajout de capacité par les concerns, plutôt que par les _service objects_.
Cette approche consiste à donner une capacité (donc un comportement) à un modèle en définissant un concern qui lui est propre, et qui ne sera (a priori) pas partagé avec un autre modèle.

Par exemple, si je souhaite rendre un rendez-vous annulable, alors je vais créer le concern `Rdv::Cancellable`, et l'inclure dans le modèle `Rdv`.
Ce concern possède une méthode `cancel!` et prend en paramètre ce qui est utile dans ce contexte, si possible de manière précise :

```rb
def cancel!(author, status:)
  # ... business operations
end
```

Cette approche se combine bien avec une conception par les ressources, où chaque contrôleur ne contient que les actions CRUD (aucune action custom), et chaque action reste le plus simple possible.
Ainsi, pour annuler un rendez-vous, bien que le modèle `Cancellation` n'existe pas, je vais virtuellement créer une ressource `Cancellation`.
Pour cela, je vais effectuer un `POST` sur l'action `create` du `CancellationsController` (voir sur `Rdv::CancellationsController` pour plus de clarté).

Celui-ci pourra alors demander directement au modèle de s'annuler :

```rb
def create
  if @rdv.cancel!(current_agent, cancellation_params)
    redirect_to the_appropriate_path
  else
    render :new, notice: "Oopsie"
  end
end
```

Ainsi, pour une personne qui doit intervenir sur la logique d'annulation d'un rendez-vous, qu'elle connaisse bien la base de code ou non, elle saura :
- qu'elle peut entrer dans le sujet par le contrôleur `CancellationsController`
- qu'elle peut changer les opérations métier dans le concern `Rdv::Cancellable`

L'écriture des tests devrait également être plus évidenté :
- le cas d'usage nominal est testé dans une request spec qui couvre le contrôleur
- les cas d'usage marginaux sont testés dans cette même request spec
- les détails sur les opérations métier sont testées de façon unitaire dans la spec du concern

Enfin, en conséquence, la conception par les ressources encourage à se passer des _form objects_.
En effet, dans l'exemple ci-dessus, plutôt que d'utiliser le _form object_ `EditRdvForm` afin de gérer le formulaire, j'aurais plutôt envie d'avoir un formulaire dans le template qui utilise directement une ressource virtuelle (au sens où il n'y a pas de modèle correspondant) `:cancellation`.
Si besoin, ce formulaire peut tout à fait utiliser les attributs du rendez-vous.
S'il y a un travail spécifique à faire, alors le concern `Rdv::Cancellable` sera un bon endroit pour ajouter des accesseurs, des constantes ou tout autre élément nécessaire à l'implémentation.

En particulier, on pourra y ajouter les validations spécifiques qui doivent s'appliquer dans le contexte de l'annulation.
Par exemple :

```rb
module Rdv::Cancellable
  extend ActiveSupport::Concern

  validates :status, presence: true, on: :cancellation
  validates :cancelled_at, presence: true, on: :cancellation

  def cancel!(author, status:)
    Rdv.transaction do
      self.cancelled_at = Time.zone.now
      self.status = status
      if save(context: :cancellation)
        notify_participants(author)
      end
    end
  end

  private

  def notify_participants(author)
    # ...
  end
end
```

Les validations ne s'appliquent que dans le cadre de l'annulation.


## Décision

L'équipe décide d'explorer l'approche de capacité par les concerns, au travers de quelques exemples :

- le refactoring du _service object_ `RdvUpdater` en un concern `Rdv::Updatable`
- l'écriture de nouveaux concerns de capacités, notamment dans le cadre des participations individuelles aux rendez-vous.
