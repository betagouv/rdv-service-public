class RdvMailer < ApplicationMailer
  add_template_helper(UsersHelper)
  add_template_helper(RdvsHelper)

  def send_ics_to_user(rdv, user, serialized_previous_starts_at = nil)
    @rdv = rdv
    @previous_starts_at = parse_time(serialized_previous_starts_at)

    subject = subject(@rdv, @previous_starts_at)

    email = user.email
    attachments[@rdv.ics_name] = { mime_type: 'text/calendar', content: @rdv.to_ical_for(user) }

    mail(to: email, subject: subject)
  end

  def send_ics_to_pro(rdv, pro, serialized_previous_starts_at = nil)
    @rdv = Rdv.includes(pros: :service).find(rdv.id)
    @pro = pro
    @previous_starts_at = parse_time(serialized_previous_starts_at)
    @users = @rdv.users

    subject = subject(@rdv, @previous_starts_at)
    email = @pro.email
    attachments[@rdv.ics_name] = { mime_type: 'text/calendar', content: @rdv.to_ical_for(@pro) }

    mail(to: email, subject: subject)
  end

  private

  def subject(rdv, previous_starts_at)
    if rdv.cancelled?
      "ANNULÉ : RDV du #{l(rdv.starts_at, format: :human)}"
    elsif previous_starts_at.present?
      "Modification de la date de votre RDV"
    else
      "RDV confirmé le #{l(rdv.starts_at, format: :human)}"
    end
  end

  def parse_time(time_in_s)
    Time.parse(time_in_s) if time_in_s.present?
  end
end
