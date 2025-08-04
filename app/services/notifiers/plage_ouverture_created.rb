class Notifiers::PlageOuvertureCreated < Notifiers::PlageOuvertureBase
  private

  def notify
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture).plage_ouverture_created.deliver_later
  end
end
