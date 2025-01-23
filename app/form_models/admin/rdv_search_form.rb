class Admin::RdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids, :current_organisation, :current_agent

  def agent
    @agent ||= agent_scope.find_by(id: agent_id) if agent_id.present?
  end

  def user
    @user ||= user_scope.find_by(id: user_id) if user_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_ids motif_ids scoped_organisation_ids]
      .to_h { [_1, send(_1)] }
  end

  private

  def user_scope
    Agent::UserPolicy::TerritoryScope.new(pundit_user, User.all).resolve
  end

  def agent_scope
    Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve
  end

  def pundit_user
    @pundit_user ||= AgentOrganisationContext.new(current_agent, current_organisation)
  end
end
