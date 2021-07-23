# frozen_string_literal: true

class Admins::Grc92Mailer < ApplicationMailer
  default from: "ne-pas-repondre-grc@hauts-de-seine.fr"
  def send_sms(recipient, phone_number, message)
    mail(to: recipient, subject: phone_number) do |format|
      format.text { render plain: message }
    end
  end
end
