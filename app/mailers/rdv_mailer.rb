class RdvMailer < ApplicationMailer
  add_template_helper(UsersHelper)
  add_template_helper(RdvsHelper)

  def send_ics_to_user(rdv, user)
    @rdv = rdv
    ics = Rdv::Ics.new(rdv: @rdv)
    attachments[ics.name] = { mime_type: 'text/calendar', content: ics.to_ical_for(user) }
    mail(to: user.email, subject: subject(@rdv))
  end

  private

  def subject(rdv)
    "RDV confirmé le #{l(rdv.starts_at, format: :human)}"
  end

  def parse_time(time_in_s)
    Time.parse(time_in_s) if time_in_s.present?
  end
end
