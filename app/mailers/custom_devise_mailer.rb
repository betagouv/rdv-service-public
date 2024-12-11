class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"

  after_action :set_no_reply_for_users

  def invitation_instructions(record, token, opts = {})
    @token = token
    @user_params = opts[:user_params] || {}
    if record.is_a?(Agent) && record.conseiller_numerique? && record.invited_by.nil?
      opts[:subject] = "📧 Invitation sur RDV Aide Numérique"
      devise_mail(record, :invitation_instructions_cnfs, opts)
    else
      opts[:reply_to] = record.invited_by&.email
      opts[:subject] = I18n.t("devise.mailer.invitation_instructions.subject", domain_name: record.domain.name)
      devise_mail(record, :invitation_instructions, opts)
    end
  end

  private

  def set_no_reply_for_users
    mail.from = no_reply_from if @resource.is_a?(User)
  end

  def domain
    resource.domain
  end
end
