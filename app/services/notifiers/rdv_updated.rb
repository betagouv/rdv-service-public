# frozen_string_literal: true

class Notifiers::RdvUpdated < Notifiers::RdvBase
  def rdvs_users_to_notify
    @rdv.rdvs_users.not_cancelled.where(send_lifecycle_notifications: true)
  end

  def notify_user_by_mail(user)
    starts_at = @rdv.attribute_before_last_save(:starts_at)
    lieu_id = @rdv.attribute_before_last_save(:lieu_id)
    user_mailer(user).rdv_updated(starts_at: starts_at, lieu_id: lieu_id).deliver_later
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_updated(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later
  end

  def notify_agent(agent)
    starts_at = @rdv.attribute_before_last_save(:starts_at)
    lieu_id = @rdv.attribute_before_last_save(:lieu_id)
    agent_mailer(agent).rdv_updated(starts_at: starts_at, lieu_id: lieu_id).deliver_later
  end
end
