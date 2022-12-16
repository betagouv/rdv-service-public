# frozen_string_literal: true

class Admins::SfrMail2SmsMailer < ApplicationMailer
  default reply_to: nil

  def send_sms(recipient_and_from_email, phone_number, message)
    headers["Content-Type"] = "text/plain"

    delivery_options = {
      user_name: ENV["ALTERNATE_SMTP_USERNAME"],
      password: ENV["ALTERNATE_SMTP_PASSWORD"],
      address: ENV["ALTERNATE_SMTP_ADDRESS"],
      port: ENV["ALTERNATE_SMTP_PORT"],
      authentication: ENV["ALTERNATE_SMTP_AUTHENTIFICATION"],
    }

    recipient, from = recipient_and_from_email.split("/")

    mail(to: recipient, from: from, subject: phone_number, delivery_method_options: delivery_options) do |format|
      format.text { render plain: "#{message}\n-- RDV-Solidarités" }
    end
  end

  def domain
    Domain::RDV_SOLIDARITES
  end
end
