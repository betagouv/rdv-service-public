class Notifiers::PlageOuvertureDestroyed < Notifiers::PlageOuvertureBase
  def initialize(plage_ouverture)
    super
    @plage_ouverture_serialized = PlageOuverture.serialize_for_active_job(plage_ouverture).merge(motif_ids: plage_ouverture.motif_ids)
  end

  private

  def notify
    # On passe la plage au job sous forme sérialisée puisqu'elle n'existe plus en base.
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture_serialized).plage_ouverture_destroyed.deliver_later
  end
end
