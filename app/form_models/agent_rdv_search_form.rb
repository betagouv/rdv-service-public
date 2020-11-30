class AgentRdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_id, :status, :show_user_details

  def organisation
    @organisation ||= Organisation.find(organisation_id) if organisation_id.present?
  end

  def agent
    @agent ||= Agent.find(agent_id) if agent_id.present?
  end

  def user
    @user ||= User.find(user_id) if user_id.present?
  end

  def lieu
    @lieu ||= Lieu.find(lieu_id) if lieu_id.present?
  end

  def rdvs
    rdvs = Rdv.where(organisation: organisation)
    rdvs = rdvs.with_agent(agent) if agent.present?
    rdvs = rdvs.with_user(user) if user.present?
    rdvs = rdvs.with_lieu(lieu) if lieu.present?
    rdvs = rdvs.status(status) if status.present?
    rdvs = rdvs.where("DATE(starts_at) >= ?", start) if start.present?
    rdvs = rdvs.where("DATE(starts_at) <= ?", send(:end)) if send(:end).present?
    rdvs
  end

  def to_query
    [:organisation_id, :start, :end, :agent_id, :user_id, :status, :show_user_details, :lieu_id]
      .map { [_1, send(_1)] }.to_h
  end
end
