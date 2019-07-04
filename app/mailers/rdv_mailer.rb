class RdvMailer < ApplicationMailer
  add_template_helper(UsersHelper)

  def send_ics_to_user(rdv)
    @rdv = rdv

    subject = "RDV confirmé le #{l(@rdv.start_at, format: :human)}"
    email = @rdv.user.email
    attachments[@rdv.ics_name] = { mime_type: 'text/calendar', content: @rdv.to_ical }

    mail(to: email, subject: subject)
  end

  def send_ics_to_pro(rdv, pro)
    @rdv = rdv
    @pro = pro
    @user = @rdv.user

    subject = "RDV confirmé le #{l(@rdv.start_at, format: :human)}"
    email = @pro.email
    attachments[@rdv.ics_name] = { mime_type: 'text/calendar', content: @rdv.to_ical }

    mail(to: email, subject: subject)
  end
end
