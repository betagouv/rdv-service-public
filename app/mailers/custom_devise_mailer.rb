class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include CommonMailer
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer",
          reply_to: proc { inviter_or_default }

  def invitation_instructions(record, token, opts = {})
    @token = token
    @user_params = opts[:user_params] || {}
    if record.is_a?(Agent) && record.conseiller_numerique? && record.invited_by.nil?
      opts[:subject] = "📧 Invitation sur RDV Aide Numérique"
      opts[:cc] = record.cnfs_secondary_email if record.cnfs_secondary_email.present?
      devise_mail(record, :invitation_instructions_cnfs, opts)
    else
      opts[:subject] = I18n.t("devise.mailer.invitation_instructions.subject", domain_name: record.domain.name)
      devise_mail(record, :invitation_instructions, opts)
    end
  end

  private

  def inviter_or_default
    return unless resource.is_a? Agent

    resource.invited_by&.email || default_from
  end

  def domain
    resource.domain
  end
end
