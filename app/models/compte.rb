# Utilisé uniquement au niveau du SuperAdmin, pour ouvrir un compte
class Compte
  include ActiveModel::Model

  attr :territory, :organisation, :address, :agent

  # Utilisé par Administrate afin de récupérer la liste des objets (ou ressources)
  # Nécessaire parce que la classe n'hérite pas de ActiveRecord::Base
  def self.default_scoped
    Territory.none
  end

  # Cette méthode est nécessaire pour que Administrate affiche le bouton de création d'une nouvelle resource
  # Autrement, #to_s génère une valeurs sous la forme "Compte#11111" qui ne match avec aucune route
  def to_s
    "compte"
  end
end
