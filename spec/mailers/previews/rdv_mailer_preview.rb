class RdvMailerPreview < ActionMailer::Preview
  def send_ics_to_user
    RdvMailer.send_ics_to_user(Rdv.last)
  end

  def send_ics_to_pro
    RdvMailer.send_ics_to_pro(Rdv.last, Pro.last)
  end
end
