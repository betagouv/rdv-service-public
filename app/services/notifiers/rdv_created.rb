# frozen_string_literal: true

class Notifiers::RdvCreated < Notifiers::RdvBase
  def notify_user_by_mail(user)
    user_mailer(user).rdv_created.deliver_later
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_created(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later
  end

  protected

  def rdvs_users_to_notify
    # Todo : test this not_excused
    @rdv.rdvs_users.not_excused.where(send_lifecycle_notifications: true)
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_created.deliver_later
  end
end
