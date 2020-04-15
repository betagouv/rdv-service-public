class RdvMailerPreview < ActionMailer::Preview
  def send_ics_to_user
    rdv = Rdv.active.last
    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def cancellation
    rdv = Rdv.active.last
    RdvMailer.cancellation(rdv, rdv.users.first)
  end
end
