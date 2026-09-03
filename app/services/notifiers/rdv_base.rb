class Notifiers::RdvBase < BaseService
  include Notifiers::AgentsConcern

  attr_reader :author, :rdv

  # Base class for Rdv notifiers.
  # Subclasses implement the notify_* methods:
  # :notify_user_by_mail(user)
  # :notify_user_by_sms(user)
  # :notify_user_by_ami(user)
  # :notify_agent(agent)

  # By default, notifications are sent to all the rdv users
  # The optional `users` argument can be used to send notifications to them instead of rdv.users
  def initialize(rdv, author, users = nil)
    @rdv = rdv
    @author = author
    @users = users || participations_to_notify.map(&:user)
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    notify_agents
    notify_users
  end

  def notify_users
    notify_users_by_mail
    notify_users_by_sms
    notify_users_by_ami
  end

  ## Configured Mailers
  #
  def user_mailer(user)
    Users::RdvMailer.with(rdv: @rdv, user: user)
  end

  def agent_mailer(agent)
    Agents::RdvMailer.with(rdv: @rdv, agent: agent, author: @author)
  end

  private

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

  def notify_users_by_ami
    users_to_notify.select do |user|
      UserAmiProfile.find_by(user: user, notify_by_ami: true).present?
    end.each do |user|
      notify_user_by_ami(user)
    end
  end

  def users_to_notify
    @users.map(&:user_to_notify).uniq
  end
end
