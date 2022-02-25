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

    generate_invitation_tokens

    notify_users_by_mail
    notify_users_by_sms
    notify_agents

    OpenStruct.new(success?: true, rdv_tokens_by_user_id: @rdv_tokens_by_user_id)
  end

  private

  ## Users notifications
  #

  def notify_users_by_mail
    return unless methods.include?(:notify_user_by_mail)

    users_to_notify
      .select(&:notifiable_by_email?)
      .each { notify_user_by_mail(_1) }
  end

  def notify_users_by_sms
    return unless methods.include?(:notify_user_by_sms)

    users_to_notify
      .select(&:notifiable_by_sms?)
      .each { notify_user_by_sms(_1) }
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

  ## Compute invitation tokens sent in notifications links to change the rdv
  #

  def generate_invitation_tokens
    @rdv_tokens_by_user_id = rdvs_users_to_notify.to_h do |rdv_user|
      rdv_user.invite! do |rdv_u|
        rdv_u.skip_invitation = true
        rdv_u.raw_invitation_token
      end
      [rdv_user.user.id, rdv_user.raw_invitation_token]
    end
  end
end
