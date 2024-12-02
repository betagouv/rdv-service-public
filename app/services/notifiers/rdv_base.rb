class Notifiers::RdvBase < BaseService
  include DateHelper
  attr_reader :participations_tokens_by_user_id

  # Base class for Rdv notifiers.
  # Subclasses implement the notify_* methods:
  # :notify_user_by_mail(user)
  # :notify_user_by_sms(user)
  # :notify_agent(agent)

  # By default, notifications are sent to all the rdv users
  # The optional `users` argument can be used to send notifications to them instead of rdv.users
  def initialize(rdv, author, users = nil)
    @rdv = rdv
    @author = author
    @users = users || participations_to_notify.map(&:user)
    @participations_tokens_by_user_id = {}
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    generate_invitation_tokens

    notify_users_by_mail
    notify_users_by_sms
    notify_agents
  end

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

  def generate_invitation_tokens
    # Prevent token generation to trigger a webhook notification,
    # because generating the Participation tokens does not change any of the
    # attributes or associations of the Rdv.
    @rdv.skip_webhooks = true

    @rdv.participations.each do |participation|
      participant = participation.user
      user_to_notify = participant.user_to_notify
      @participations_tokens_by_user_id[user_to_notify.id] = participation.new_raw_invitation_token
    end

    @rdv.skip_webhooks = false
  end

  ## Configured Mailers
  #
  def user_mailer(user)
    Users::RdvMailer.with(rdv: @rdv, user: user, token: @participations_tokens_by_user_id[user.id])
  end

  def agent_mailer(agent)
    Agents::RdvMailer.with(rdv: @rdv, agent: agent, author: @author)
  end

  private

  def users_to_notify
    @users.map(&:user_to_notify).uniq
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
