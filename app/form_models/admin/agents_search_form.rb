class Admin::AgentsSearchForm
  include ActiveModel::Validations

  attr_reader :role, :query, :current_organisation

  def initialize(current_organisation:, role: nil, query: nil)
    @current_organisation = current_organisation
    @role = role
    @query = query
  end

  def filter_agents(agents_ar)
    agents_ar = organisation_scope(agents_ar)
    agents_ar = agents_ar.search_by_text(query) if query.present?
    agents_ar = agents_ar.merge(AgentRole.access_level_admin) if role == "admin"
    agents_ar.order(Arel.sql("(invitation_sent_at IS NOT NULL AND invitation_accepted_at IS NULL) DESC")).ordered_by_last_name
  end

  # Restreint la relation aux agents de l'organisation courante, via la table de jointure des rôles
  def organisation_scope(agents_ar)
    agents_ar.joins(:roles).where(agent_roles: { organisation_id: current_organisation.id })
  end

  def active_filters? = role.present? || query.present?

  def should_display?
    current_organisation.agents.active.limit(10).count == 10 ||
      (current_organisation.agent_roles.basic.any? && current_organisation.agent_roles.admin.any?) ||
      active_filters?
  end
end
