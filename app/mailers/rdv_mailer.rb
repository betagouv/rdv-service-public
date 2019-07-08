class RdvMailer < ApplicationMailer
  add_template_helper(UsersHelper)

  def send_ics_to_user(rdv, serialized_previous_start_at = nil)
    @rdv = rdv
    @previous_start_at = Time.parse(serialized_previous_start_at) if serialized_previous_start_at.present?

    subject = if @rdv.cancelled?
                "ANNULÉ : RDV du #{l(@rdv.start_at, format: :human)}"
              elsif @previous_start_at.present?
                "Modification de votre RDV le #{l(@rdv.start_at, format: :human)}"
              else
                "RDV confirmé le #{l(@rdv.start_at, format: :human)}"
              end

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
