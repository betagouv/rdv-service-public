class Notifiers::RdvCreated < Notifiers::RdvBase
  def notify_user_by_mail(user)
    user_mailer(user).rdv_created.deliver_later
  end

  def notify_user_by_sms(user)
    # Nous envoyons un SMS lors de la création du RDV si :
    # - le RDV est dans moins de 48H
    # - OU le RDV a été créé par un agent
    # - OU le RDV a été créé par un usager mais iel n’a pas de compte (c’est le parcours pour les invitations de RDVI)
    #
    # Pour les RDV créés par un usager plus de 48H avant, iels auront un SMS de rappel 48h avant ce RDV
    # il n’est donc pas nécessaire d’envoyer ce SMS à la création du RDV.

    if self.class.should_send_sms_to_user?(user:, rdv: @rdv, author: @rdv.created_by)
      Users::RdvSms.rdv_created(@rdv, user, @participations_tokens_by_user_id[user.id]).deliver_later
    end
  end

  def self.should_send_sms_to_user?(user:, rdv:, author:)
    author != user || !user.confirmed? || rdv.starts_at < 2.days.from_now
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
