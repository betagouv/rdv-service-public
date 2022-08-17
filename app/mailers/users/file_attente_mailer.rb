# frozen_string_literal: true

class Users::FileAttenteMailer < ApplicationMailer
  before_action do
    @rdv = params[:rdv]
    @user = params[:user]
    @token = params[:token]
  end

  default to: -> { @user.email }, reply_to: -> { TransferEmailReplyJob.reply_address_for_rdv(@rdv) }

  def new_creneau_available
    subject = t("users.file_attente_mailer.new_creneau_available.title")
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
