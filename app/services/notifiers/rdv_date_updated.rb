# frozen_string_literal: true

class Notifiers::RdvDateUpdated < Notifiers::RdvBase
  protected

  def rdvs_users_to_notify
    @rdv.rdvs_users.where(send_lifecycle_notifications: true)
  end

  def notify_user_by_mail(user)
    user_mailer(user).rdv_date_updated(@rdv.attribute_before_last_save(:starts_at)).deliver_later
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_date_updated(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_date_updated(@rdv.attribute_before_last_save(:starts_at)).deliver_later
  end
end
