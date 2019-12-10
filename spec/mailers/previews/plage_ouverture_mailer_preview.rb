class PlageOuvertureMailerPreview < ActionMailer::Preview
  def send_ics_to_agent
    plage_ouverture = PlageOuverture.last
    PlageOuvertureMailer.send_ics_to_agent(plage_ouverture)
  end
end
