class Admin::RdvSearchForm
  include ActiveModel::Model
  include Pundit::Authorization

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids, :pundit_user, :per

  def agent
    @agent ||= agent_scope.find_by(id: agent_id) if agent_id.present?
  end

  def user
    @user ||= user_scope.find_by(id: user_id) if user_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_ids motif_ids scoped_organisation_ids]
      .index_with { send(_1) }
  end

  private

  def user_scope
    policy_scope(User, policy_scope_class: Agent::UserPolicy::TerritoryScope)
  end

  def agent_scope
    policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
  end
end
