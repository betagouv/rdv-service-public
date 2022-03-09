# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper

  def invitation_instructions(record, token, opts = {})
    @token = token
    @user_params = opts[:user_params] || {}
    opts[:reply_to] = record.invited_by.email if record.is_a? Agent
    devise_mail(record, :invitation_instructions, opts)
  end
end
