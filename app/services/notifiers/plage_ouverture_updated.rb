class Notifiers::PlageOuvertureUpdated < Notifiers::PlageOuvertureBase
  private

  def notify
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture).plage_ouverture_updated.deliver_later
  end
end
