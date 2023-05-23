# frozen_string_literal: true

# Utilisé uniquement au niveau du SuperAdmin, afin de faciliter la création d'accès pour les Mairies
class MairieCompte
  include ActiveModel::Model

  attr_accessor :id, :name, :address, :agent_first_name, :agent_last_name, :agent_email

  # Utilisé par Administrate afin de récupérer la liste des objets (ou ressources)
  # Nécessaire parce que la classe n'hérite pas de ActiveRecord::Base
  def self.default_scoped
    Lieu.joins(:organisation).where(organisations: { verticale: :rdv_mairie })
  end

  # Cette méthode est nécessaire pour que Administrate affiche le bouton de création d'une nouvelle resource
  # Autrement, #to_s génère une valeurs sous la forme "MairieCompte#11111" qui ne match avec aucune route
  def to_s
    "mairie_compte"
  end
end
