class CustomDeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"
  layout "mailer"

  def invitation_instructions(record, token, opts = {})
    @token = token
    @prefill_params = opts[:prefill_params] || {}
    opts[:reply_to] = record.invited_by.email if record.is_a? Agent
    devise_mail(record, :invitation_instructions, opts)
  end
end
