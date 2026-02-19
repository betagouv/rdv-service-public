class Notifiers::ParticipationCancelled < BaseService
  include DateHelper
  include Notifiers::AgentsConcern

  attr_reader :participation, :author

  def initialize(participation:, author:)
    @participation = participation
    @author = author
  end

  def perform
    return if rdv.starts_at < Time.zone.now

    participation.set_restricted_authentication_token_if_missing_and_save

    notify_user
    notify_agents
  end

  private

  def notify_user
    return unless participation.send_lifecycle_notifications?

    if user.notifiable_by_email?
      Users::RdvMailer.with(rdv:, user:, token:, participation:).participation_cancelled.deliver_later
    end

    if user.notifiable_by_sms? && (author.is_a?(Agent) || author.is_a?(Prescripteur))
      Users::RdvSms.participation_cancelled(rdv, user, token).deliver_later
    end
  end

  def notify_agent(agent)
    Agents::RdvMailer.with(participation:, agent:, author:).participation_cancelled.deliver_later
  end

  def rdv = participation.rdv
  def user = participation.user.user_to_notify
  def token = participation.restricted_auth_token
end
