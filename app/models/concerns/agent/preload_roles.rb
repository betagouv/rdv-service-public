# Ce concern regroupe les méthodes utilisées pour éviter de faire plusieurs
# requêtes à Postgres à chaque chargement de page pour récupérer :
# - les droits de l'agent courant sur l'organisation courante
# - le nombre d'organisations de l'agent courant

module Agent::PreloadRoles
  extend ActiveSupport::Concern

  # Précharger les `roles` à chaque requête permet d'utiliser des helpers
  # conçus pour manipuler des agents avec des `roles` préchargés.
  def preload_roles
    roles.load
  end

  def organisations_count
    # Si `roles` est chargé, `size` va compter les objets, sinon elle va envoyer un COUNT en base
    roles.size
  end

  def organisation_ids
    if roles.loaded?
      roles.map(&:organisation_id)
    else
      super
    end
  end
end
