class Notifiers::RdvCancelled < Notifiers::RdvBase
  def notify_user_by_mail(user)
    return unless notify_cancellation?

    user_mailer(user).rdv_cancelled.deliver_later
  end

  def notify_user_by_sms(user)
    # On envoie des SMS de notification de RDV annulé uniquement si l'auteur de l'annulation est un Agent ou un Prescripteur et qu’il ne s’agit pas d’un no-show.
    return unless @author.is_a?(Agent) || @author.is_a?(Prescripteur)
    return unless notify_cancellation?

    Users::RdvSms.rdv_cancelled(@rdv, user, @participations_tokens_by_user_id[user.id]).deliver_later
  end

  protected

  def notify_cancellation?
    # if the rdv is collectif, there can still be cancellation notification if a participant is removed (regardless of the rdv status)
    return true if @rdv.collectif?

    # Only send sms for excused cancellations (not for no-show)
    @rdv.status.in?(Rdv::CANCELLED_STATUSES)
  end

  def participations_to_notify
    @rdv.participations.where(send_lifecycle_notifications: true)
  end

  def notify_agent(agent)
    agent_mailer(agent).rdv_cancelled.deliver_later
  end
end
