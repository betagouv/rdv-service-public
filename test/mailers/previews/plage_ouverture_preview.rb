class PlageOuvertureMailerPreview < ActionMailer::Preview
  def send_ics_to_agent
    PlageOuvertureMailer.send_ics_to_agent(PlageOuverture.last)
  end
end
