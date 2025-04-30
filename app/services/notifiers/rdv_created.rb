class Notifiers::RdvCreated < Notifiers::RdvBase
  def notify_user_by_mail(user)
    user_mailer(user).rdv_created.deliver_later
  end

  def notify_user_by_sms(user)
    # Nous n'envoyons pas de SMS de confirmation si le rendez-vous a été pris en ligne par l’usager sauf si le RDV
    # est dans moins de 2 jours (car l’usager n’aura pas de SMS de rappel) ou que l’usager n’a pas confirmé son compte
    # (cas notamment pour la prise de RDV par invitation)
    if !(@rdv.created_by_user? && user.confirmed?) || @rdv.starts_at < 2.days.from_now
      Users::RdvSms.rdv_created(@rdv, user, @participations_tokens_by_user_id[user.id]).deliver_later
    end
  end

  protected

  def participations_to_notify
    # Rdv_created with cancelled status is not supposed to happen
    @rdv.participations.not_cancelled.where(send_lifecycle_notifications: true)
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_created.deliver_later
  end
end
