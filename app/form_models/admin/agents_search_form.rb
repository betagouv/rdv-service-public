class Admin::AgentsSearchForm
  include ActiveModel::Validations

  attr_reader :role, :query, :current_organisation

  def initialize(current_organisation:, role: nil, query: nil)
    @current_organisation = current_organisation
    @role = role
    @query = query
  end

  def filter_agents(agents_ar)
    agents_ar = agents_ar.joins(:organisations).where(organisations: { id: current_organisation.id })
    agents_ar = agents_ar.search_by_text(query) if query.present?
    agents_ar = agents_ar.order(Arel.sql("(invitation_sent_at IS NOT NULL AND invitation_accepted_at IS NULL) DESC")).ordered_by_last_name

    if role == "admin"
      agents_ar = agents_ar.where(
        id: AgentRole.where(organisation_id: current_organisation.id, access_level: AgentRole::ACCESS_LEVEL_ADMIN).select(:agent_id)
      )
    end

    agents_ar
  end

  def resettable? = role.present? || query.present?
end
