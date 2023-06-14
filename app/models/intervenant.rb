# frozen_string_literal: true

class Intervenant < AgentBase
  self.table_name = "agents"
  include Agent::SearchConcern

  # Validation
  validate :all_roles_intervenant

  def all_roles_intervenant
    unless all_roles_intervenant?
      errors.add(:roles, "doivent tous être 'intervenant'")
    end
  end

  def all_roles_intervenant?
    roles.present? && roles.to_a.all? { |role| role.access_level == "intervenant" }
  end
end
