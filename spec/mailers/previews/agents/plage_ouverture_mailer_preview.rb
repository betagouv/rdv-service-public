class Agents::PlageOuvertureMailerPreview < ActionMailer::Preview
  def plage_ouverture_created
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_created(Admin::Ics::PlageOuverture.create_payload(plage_ouverture))
  end

  def plage_ouverture_updated
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_updated(Admin::Ics::PlageOuverture.create_payload(plage_ouverture))
  end

  def plage_ouverture_destroyed
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_destroyed(Admin::Ics::PlageOuverture.create_payload(plage_ouverture))
  end
end
