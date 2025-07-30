class Notifiers::PlageOuvertureDestroyed < Notifiers::PlageOuvertureBase
  def initialize(plage_ouverture, motif_ids)
    @motif_ids = motif_ids
    super(plage_ouverture)
  end

  private

  def notify
    # On passe la plage au job sous forme sérialisée puisqu'elle n'existe plus en base.
    plage_attributes = PlageOuverture.serialize_for_active_job(@plage_ouverture).merge(motif_ids: @motif_ids)
    Agents::PlageOuvertureMailer.with(plage_ouverture: plage_attributes).plage_ouverture_destroyed.deliver_later
  end
end
