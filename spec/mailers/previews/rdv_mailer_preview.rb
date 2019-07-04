class RdvMailerPreview < ActionMailer::Preview
  def send_ics_to_user
    RdvMailer.send_ics_to_user(Rdv.last)
  end
end
