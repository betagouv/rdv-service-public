class Notifiers::ParticipationCreated < BaseService
  include DateHelper
  include Notifiers::AgentsConcern

  attr_reader :participation, :author

  def initialize(participation:, author:)
    @participation = participation
    @author = author
  end

  def perform
    return unless rdv.collectif? # garde-fou

    return if rdv.starts_at < Time.zone.now

    participation.set_restricted_authentication_token_if_missing_and_save

    notify_user
    notify_agents
  end

  private

  def notify_user
    return unless participation.send_lifecycle_notifications?

    if user.notifiable_by_email?
      Users::RdvMailer.with(rdv:, user:, token:).rdv_created.deliver_later
    end

    if user.notifiable_by_sms? && Notifiers::RdvCreated.should_send_sms_to_user?(user:, rdv:, author:)
      Users::RdvSms.rdv_created(rdv, user, token).deliver_later
    end
  end

  def notify_agent(agent)
    Agents::RdvMailer.with(participation:, agent:, token:).participation_created.deliver_later
  end

  def rdv = participation.rdv
  def user = participation.user.user_to_notify
  def token = participation.restricted_auth_token
end
