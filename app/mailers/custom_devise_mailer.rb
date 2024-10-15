class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"

  def invitation_instructions(record, token, opts = {})
    @token = token
    @user_params = opts[:user_params] || {}
    if record.is_a?(Agent) && record.conseiller_numerique? && record.invited_by.nil?
      opts[:subject] = "📧 Invitation sur RDV Aide Numérique"
      opts[:cc] = opts[:cnfs_secondary_email] if opts[:cnfs_secondary_email].present?
      devise_mail(record, :invitation_instructions_cnfs, opts)
    else
      opts[:reply_to] = record.invited_by&.email
      opts[:subject] = I18n.t("devise.mailer.invitation_instructions.subject", domain_name: record.domain.name)
      devise_mail(record, :invitation_instructions, opts)
    end
  end

  private

  def domain
    resource.domain
  end
end
