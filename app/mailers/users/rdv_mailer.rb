# frozen_string_literal: true

class Users::RdvMailer < ApplicationMailer
  include DateHelper
  add_template_helper UsersHelper
  add_template_helper RdvsHelper
  add_template_helper DateHelper

  def rdv_created(rdv_payload, user)
    @rdv = OpenStruct.new(rdv_payload)
    @user = user

    attachments[rdv_payload[:name]] = {
      mime_type: "text/calendar",
      content: IcalHelpers::Ics.from_payload(rdv_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }
    mail(
      to: user.email,
      subject: "RDV confirmé le #{l(@rdv.starts_at, format: :human)}"
    )
  end

  def rdv_date_updated(rdv_payload, user, old_starts_at)
    @rdv = OpenStruct.new(rdv_payload)
    @user = user
    @old_starts_at = old_starts_at

    attachments[rdv_payload[:name]] = {
      mime_type: "text/calendar",
      content: IcalHelpers::Ics.from_payload(rdv_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }
    mail(
      to: user.email,
      subject: "RDV #{relative_date old_starts_at} reporté à plus tard"
    )
  end

  def rdv_upcoming_reminder(rdv_payload, user)
    @rdv = OpenStruct.new(rdv_payload)
    @user = user
    mail(
      to: user.email,
      subject: "[Rappel] RDV le #{l(@rdv.starts_at, format: :human)}"
    )
  end

  def rdv_cancelled(rdv_payload, user, author)
    @rdv = OpenStruct.new(rdv_payload)
    @user = user
    @author = author
    mail(
      to: user.email,
      subject: "RDV annulé le #{l(@rdv.starts_at, format: :human)} avec #{@rdv.organisation_name}"
    )
  end
end
