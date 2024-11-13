class Users::RdvMailer < ApplicationMailer
  include DateHelper
  helper UsersHelper
  helper RdvsHelper
  helper DateHelper
  helper MotifsHelper

  before_action do
    @rdv = params[:rdv]
    @user = params[:user]
    @token = params[:token]
  end

  default to: -> { @user.email }, reply_to: -> { TransferEmailReplyJob.reply_address_for_rdv(@rdv) }

  def rdv_created
    self.ics_payload = @rdv.payload(:create, @user)
    subject = t("users.rdv_mailer.rdv_created.title", date: l(@rdv.starts_at, format: :human))
    mail(subject: subject)
    save_receipt(subject)
  end

  def rdv_updated(old_starts_at:, lieu_id:)
    @old_starts_at = old_starts_at
    @address_name = Lieu.find(lieu_id).full_name if lieu_id

    self.ics_payload = @rdv.payload(:update, @user)
    subject = t("users.rdv_mailer.rdv_updated.title", date: l(@old_starts_at, format: :human))
    mail(subject: subject)
    save_receipt(subject)
  end

  def rdv_upcoming_reminder
    self.ics_payload = @rdv.payload(nil, @user)
    subject = t("users.rdv_mailer.rdv_upcoming_reminder.title", date: l(@rdv.starts_at, format: :human))
    mail(subject: subject)
    save_receipt(subject)
  end

  def rdv_cancelled
    self.ics_payload = @rdv.payload(:destroy, @user)
    subject = t("users.rdv_mailer.rdv_cancelled.title", date: l(@rdv.starts_at, format: :human), organisation: @rdv.organisation.name)
    mail(subject: subject)
    save_receipt(subject)
  end

  private

  def save_receipt(subject)
    Receipt.create!(rdv: @rdv, user: @user, event: action_name, channel: :mail, result: :processed, email_address: @user.email, content: subject)
  end

  def domain
    @rdv.domain
  end
end
