class Users::RdvMailer < ApplicationMailer
  add_template_helper(UsersHelper)
  add_template_helper(RdvsHelper)

  def rdv_created(rdv, user)
    @rdv = rdv
    @user = user

    rdv_payload = Admin::Ics::Rdv.payload(@rdv, @user)

    attachments[rdv_payload[:name]] = {
      mime_type: "text/calendar",
      content: Admin::Ics::Rdv.to_ical(rdv_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }
    mail(
      to: user.email,
      subject: "RDV confirmé le #{l(rdv.starts_at, format: :human)}"
    )
  end

  def rdv_upcoming_reminder(rdv, user)
    @rdv = rdv
    @user = user
    mail(
      to: user.email,
      subject: "[Rappel] RDV le #{l(rdv.starts_at, format: :human)}"
    )
  end

  def rdv_cancelled_by_agent(rdv, user)
    @rdv = rdv
    @user = user
    mail(
      to: user.email,
      subject: "RDV annulé le #{l(rdv.starts_at, format: :human)} avec #{rdv.organisation.name}"
    )
  end

  def rdv_cancelled_by_user(rdv, user)
    @rdv = rdv
    @user = user
    mail(
      to: user.email,
      subject: "RDV annulé le #{l(rdv.starts_at, format: :human)} avec #{rdv.organisation.name}"
    )
  end
end
