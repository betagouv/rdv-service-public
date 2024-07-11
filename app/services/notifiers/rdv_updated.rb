class Notifiers::RdvUpdated < Notifiers::RdvBase
  def initialize(rdv, author, users = nil, old_agent_ids:)
    super(rdv, author, users)
    @old_agent_ids = old_agent_ids || rdv.agent_ids
  end

  def participations_to_notify
    @rdv.participations.not_cancelled.where(send_lifecycle_notifications: true)
  end

  def notify_user_by_mail(user)
    starts_at = @rdv.attribute_before_last_save(:starts_at)
    lieu_id = @rdv.attribute_before_last_save(:lieu_id)
    user_mailer(user).rdv_updated(starts_at: starts_at, lieu_id: lieu_id).deliver_later
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_updated(@rdv, user, @participations_tokens_by_user_id[user.id]).deliver_later
  end

  def agents_to_notify
    Agent.where(id: @old_agent_ids + @rdv.agent_ids).select { should_notify_agent(_1) }
  end

  def notify_agent(agent)
    starts_at = @rdv.attribute_before_last_save(:starts_at)
    lieu_id = @rdv.attribute_before_last_save(:lieu_id)
    old_agents = Agent.where(id: @old_agent_ids)

    if agent.in?(@rdv.agents) && !agent.in?(old_agents)
      agent_mailer(agent).rdv_created.deliver_later
    elsif agent.in?(@rdv.agents) && agent.in?(old_agents)
      agent_mailer(agent).rdv_updated(starts_at: starts_at, lieu_id: lieu_id).deliver_later
    elsif !agent.in?(@rdv.agents) && agent.in?(old_agents)
      agent_mailer(agent).rdv_cancelled(starts_at: starts_at).deliver_later
    end
  end
end
