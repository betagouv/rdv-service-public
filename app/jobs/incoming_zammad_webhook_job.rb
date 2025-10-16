class IncomingZammadWebhookJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :latency_whenever

  self.log_arguments = false

  def perform(payload)
    @ticket = payload["ticket"]
    body_html = match_user_with_email || match_user_with_phone_number || no_match
    ZammadApiClient.create_note(ticket_id: ticket["id"], body_html:)
  end

  private

  def match_with_email
    email = @ticket["customer"]["email"]
    return if email.blank?

    user = User.find_by(email:)
    return if user.nil?

    "Un usager a été trouvé avec l’email #{email}\n\n#{link_to_super_admin_user(user)}"
  end

  def link_to_super_admin_user(user)
    <<~HTML
      <a href="#{super_admins_user_url(user, host:)}">
        Voir l’usager dans la super admin
      </a>
    HTML
  end

  def host
    Domain.default_domain_for_current_instance.host_name
  end
end
