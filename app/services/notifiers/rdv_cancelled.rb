# frozen_string_literal: true

class Notifiers::RdvCancelled < Notifiers::RdvBase
  def notify_user_by_mail(user)
    return unless notify_cancellation?

    user_mailer(user).rdv_cancelled.deliver_later
  end

  def notify_user_by_sms(user)
    # Only send sms for excused cancellations by an Agent (not for no-show, not for self-cancellation)
    return unless @author.is_a? Agent
    return unless notify_cancellation?

    Users::RdvSms.rdv_cancelled(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later
  end

  protected

  def notify_cancellation?
    # if the rdv is collectif, there can still be cancellation notification if a participant is removed (regardless of the rdv status)
    return true if @rdv.collectif?

    # Only send sms for excused cancellations (not for no-show)
    @rdv.status.in?(%w[excused revoked])
  end

  def rdvs_users_to_notify
    # Do not notify users for cancel statuses for already cancelled rdvs
    @rdv.rdvs_users.where(send_lifecycle_notifications: true).each do |rdv_user|
      return rdv_user if rdv_user.previous_changes["status"]&.first.in? %w[excused revoked]
    end
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_cancelled.deliver_later
  end
end
