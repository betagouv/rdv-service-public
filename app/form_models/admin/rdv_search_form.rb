class Admin::RdvSearchForm
  include ActiveModel::Model
  include Pundit::Authorization

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids, :pundit_user

  def agent
    @agent ||= agent_scope.find_by(id: agent_id) if agent_id.present?
  end

  def user
    @user ||= user_scope.find_by(id: user_id) if user_id.present?
  end

  def lieux
    @lieux ||= Agent::LieuPolicy::Scope.new(pundit_user.agent, Lieu.where(id: lieu_ids)).resolve
  end

  def motifs
    @motifs ||= Agent::MotifPolicy::ScopeForRdvsList.new(pundit_user.agent, Motif.where(id: motif_ids)).resolve
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_ids motif_ids scoped_organisation_ids]
      .index_with { send(_1) }
  end

  def self.valid_date?(date)
    return false if date.blank? || date.to_s.include?("__/__/____")

    Date.parse(date.to_s)
  rescue Date::Error
    Sentry.capture_message("invalid date: #{date.inspect}", fingerprint: ["invalid date"])
    false
  end

  def applied_filters # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @applied_filters ||= begin
      filters = []
      filters << :agent if agent.present?
      filters << :user if  user.present?
      filters << :lieux if lieux.present?
      filters << :motifs if motifs.present?
      filters << :status if status.present?
      filters << :dates if self.class.valid_date?(start) || self.class.valid_date?(send(:end))
      filters
    end
  end

  private

  def user_scope
    policy_scope(User, policy_scope_class: Agent::UserPolicy::TerritoryScope)
  end

  def agent_scope
    policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
  end
end
