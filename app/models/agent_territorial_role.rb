class AgentTerritorialRole < ApplicationRecord
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  # Hooks
  before_destroy :territory_has_at_least_one_role_before_destroy

  ## -

  def territory_has_at_least_one_role_before_destroy
    return if territory.roles.where.not(id: id).any?

    errors.add(:base, "Il doit toujours y avoir au moins un agent responsable par territoire")
    throw :abort
  end
end
