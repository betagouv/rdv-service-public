# frozen_string_literal: true

class Users::RdvMailer < ApplicationMailer
  add_template_helper UsersHelper
  add_template_helper RdvsHelper
  add_template_helper DateHelper

  def rdv_created(rdv, user)
    @rdv = rdv
    @user = user

    rdv_payload = @rdv.payload(nil, @user)

    attachments[rdv_payload[:name]] = {
      mime_type: "text/calendar",
      content: IcalHelpers::Ics.from_payload(rdv_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }
    mail(
      to: user.email,
      subject: "RDV confirmé le #{l(rdv.starts_at, format: :human)}"
    )
  end

  def rdv_date_updated(rdv, user, old_starts_at)
    @rdv = rdv
    @user = user
    @old_starts_at = old_starts_at

    rdv_payload = @rdv.payload(nil, @user)

    attachments[rdv_payload[:name]] = {
      mime_type: "text/calendar",
      content: IcalHelpers::Ics.from_payload(rdv_payload),
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

  def rdv_cancelled(rdv, user, author)
    @rdv = rdv
    @user = user
    @author = author
    mail(
      to: user.email,
      subject: "RDV annulé le #{l(rdv.starts_at, format: :human)} avec #{rdv.organisation.name}"
    )
  end
end
