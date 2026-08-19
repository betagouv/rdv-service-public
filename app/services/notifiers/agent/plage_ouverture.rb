class Notifiers::Agent::PlageOuverture
  def initialize(plage_ouverture, serialize: false)
    @plage_ouverture = plage_ouverture

    if serialize
      @plage_ouverture_serialized = PlageOuverture.serialize_for_active_job(plage_ouverture).merge(motif_ids: plage_ouverture.motif_ids)
    end
  end

  def created!
    perform(mailer.plage_ouverture_created)
  end

  def updated!
    perform(mailer.plage_ouverture_updated)
  end

  def destroyed!
    # On passe la plage au job sous forme sérialisée puisqu'elle n'existe plus en base.
    perform(Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture_serialized).plage_ouverture_destroyed)
  end

  private

  def perform(mailer_action)
    mailer_action.deliver_later if agent_notifiable?
  end

  def mailer
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture)
  end

  def agent_notifiable?
    @plage_ouverture.agent&.email.present? && @plage_ouverture.agent.plage_ouverture_notification_level == "all"
  end
end
