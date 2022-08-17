# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
  helper_method :domain

  def invitation_instructions(record, token, opts = {})
    @token = token
    @user_params = opts[:user_params] || {}
    opts[:reply_to] = reply_to(record)
    if record.is_a?(Agent) && record.conseiller_numerique? && record.invited_by.nil?
      devise_mail(record, :invitation_instructions_cnfs, opts)
    else
      devise_mail(record, :invitation_instructions, opts)
    end
  end

  private

  def reply_to(record)
    return unless record.is_a? Agent

    record.invited_by&.email || SUPPORT_EMAIL
  end

  def domain
    if @resource.is_a?(Agent)
      @resource.domain
    else
      # TODO: #rdv-inclusion-numerique-v1 trouver un moyen de mettre le bon domaine
      Domain::RDV_SOLIDARITES
    end
  end

  def default_url_options
    super.merge(host: domain.dns_domain_name)
  end
end
