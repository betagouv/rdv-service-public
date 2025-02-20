# ce module doit être inclus sur les instances de User individuellement et pas sur tous les User
# En effet, on ne veut pas valider systématiquement le statut des numéros de pré-demande ANTS
# Par exemple, lors d’une mise à jour d’une fiche usager par un agent, on ne veut pas valider le numéro de pré-demande ANTS
module User::AntsPreDemandeNumberStatusValidationConcern
  extend ActiveSupport::Concern

  included do
    validates(:ants_pre_demande_number, presence: true)

    # ants_meeting_point_id est utilisé dans AntsPreDemandeNumberStatusValidation
    # IMPORTANT : En plus d’inclure ce module, il faut bien penser à setter cette valeur avant le lancement des validations !
    attr_accessor :ants_meeting_point_id

    validates_with(AntsPreDemandeNumberStatusValidation)
  end
end
