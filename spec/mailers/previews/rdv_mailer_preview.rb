class RdvMailerPreview < ActionMailer::Preview
  def send_ics_to_user
    rdv = Rdv.active.last
    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def cancel_by_agent
    rdv = Rdv.active.last
    RdvMailer.cancel_by_agent(rdv, rdv.users.first)
  end
end
