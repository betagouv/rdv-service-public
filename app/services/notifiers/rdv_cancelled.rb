# frozen_string_literal: true

class Notifiers::RdvCancelled < Notifiers::RdvBase
  def notify_user_by_mail(user)
    # Only send sms for excused cancellations (not for no-show)
    # if the rdv is collectif, there can still be cancellation notification if a participant is removed (regardless of the rdv status)
    return unless @rdv.status.in?(%w[excused revoked]) || @rdv.collectif?

    user_mailer(user).rdv_cancelled.deliver_later
  end

  def notify_user_by_sms(user)
    # Only send sms for excused cancellations by an Agent (not for no-show, not for self-cancellation)
    return unless @author.is_a? Agent
    return unless @rdv.status.in?(%w[excused revoked]) || @rdv.collectif?

    Users::RdvSms.rdv_cancelled(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later
  end

  protected

  def rdvs_users_to_notify
    @rdv.rdvs_users.where(send_lifecycle_notifications: true)
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_cancelled.deliver_later
  end
end
