class Agents::PlageOuvertureMailerPreview < ActionMailer::Preview
  def plage_ouverture_created
    plage_ouverture = PlageOuverture.last
    Agents::PlageOuvertureMailer.plage_ouverture_created(plage_ouverture)
  end
end
