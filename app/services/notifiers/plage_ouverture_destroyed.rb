class Notifiers::PlageOuvertureDestroyed < Notifiers::PlageOuvertureBase
  private

  def notify
    # On passe la plage au job sous forme sérialisée puisqu'elle n'existe plus en base.
    plage_attributes = PlageOuverture.serialize_for_active_job(@plage_ouverture).merge(motif_ids: @plage_ouverture.motifs.ids)
    Agents::PlageOuvertureMailer.with(plage_ouverture: plage_attributes).plage_ouverture_destroyed.deliver_later
  end
end
