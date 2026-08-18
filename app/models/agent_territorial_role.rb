class AgentTerritorialRole < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  # Hooks
  before_destroy :territory_has_at_least_one_role_before_destroy

  ## -

  def territory_has_at_least_one_role_before_destroy
    # NB: `territory.roles` pointe maintenant vers AgentTerritorialAccessRight (cf. Territory#roles),
    # cette table n'étant plus alimentée par l'application. On requête donc cette classe directement
    # pour que cette validation historique reste correcte.
    return if AgentTerritorialRole.where(territory: territory).where.not(id: id).any?

    errors.add(:base, "Il doit toujours y avoir au moins un agent responsable par espace")
    throw :abort
  end
end
