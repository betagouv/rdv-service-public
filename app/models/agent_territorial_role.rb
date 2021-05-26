# frozen_string_literal: true

class AgentTerritorialRole < ApplicationRecord
  belongs_to :agent
  belongs_to :territory

  before_destroy :territory_has_at_least_one_role_before_destroy

  def territory_has_at_least_one_role_before_destroy
    return if territory.roles.where.not(id: id).any?

    errors.add(:base, "Il doit toujours y avoir au moins un agent responsable par territoire")
    throw :abort
  end
end
