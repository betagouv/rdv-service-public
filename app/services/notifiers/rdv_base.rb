# frozen_string_literal: true

class Notifiers::RdvBase < ::BaseService
  include DateHelper

  # Base class for Rdv notifiers.
  # Subclasses implement the notify_* methods:
  # :notify_user_by_mail(user)
  # :notify_user_by_sms(user)
  # :notify_agent(agent)

  def initialize(rdv, author)
    @rdv = rdv
    @author = author
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    notify_users_by_mail
    notify_users_by_sms
    notify_agents
  end

  private

  ## Users notifications
  #

  def notify_users_by_mail
    return unless @rdv.motif.visible_and_notified?
    return unless methods.include?(:notify_user_by_mail)

    users_to_notify
      .select(&:notifiable_by_email?)
      .each { notify_user_by_mail(_1) }
  end

  def notify_users_by_sms
    return unless @rdv.motif.visible_and_notified?
    return unless methods.include?(:notify_user_by_sms)

    users_to_notify
      .select(&:notifiable_by_sms?)
      .each { notify_user_by_sms(_1) }
  end

  def rdvs_users_to_notify
    @rdv.rdvs_users
  end

  def users_to_notify
    rdvs_users_to_notify.map(&:user).map(&:user_to_notify).uniq
  end

  ## Agents notifications
  #

  def notify_agents
    return unless methods.include?(:notify_agent)

    agents_to_notify.each { notify_agent(_1) }
  end

  def agents_to_notify
    @rdv.agents
      .select { should_notify_agent(_1) }
  end

  def should_notify_agent(agent)
    level = agent.rdv_notifications_level
    return true if level == "all"
    return false if level == "none"
    return false if @author == agent
    return false if level == "soon" && !soon_date?(@rdv.starts_at) && !soon_date?(@rdv.attribute_before_last_save(:starts_at))

    true
  end
end
