class RdvMailerPreview < ActionMailer::Preview
  def send_ics_to_user
    rdv = Rdv.where(cancelled_at: nil).last
    RdvMailer.send_ics_to_user(rdv)
  end

  def send_updated_ics_to_user
    rdv = Rdv.where(cancelled_at: nil).last
    RdvMailer.send_ics_to_user(rdv, rdv.start_at.-(2.days).to_s)
  end

  def send_cancelled_ics_to_user
    rdv = Rdv.last
    rdv.cancelled_at = Time.zone.now
    RdvMailer.send_ics_to_user(rdv)
  end

  def send_ics_to_pro
    RdvMailer.send_ics_to_pro(Rdv.last, Pro.last)
  end
end
