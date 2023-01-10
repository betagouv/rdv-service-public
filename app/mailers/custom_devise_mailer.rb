# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  self.deliver_later_queue_name = :devise

  include CommonMailer
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  helper :application
  default template_path: "devise/mailer"

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
    case resource
    when Agent
      resource.domain
    when User
      user_domain
    else
      "Unexpected resource: #{resource.inspect}"
    end
  end

  REDIS_CLIENT = Redis.new(url: Rails.configuration.x.redis_url)

  # Cette méthode détermine le domaine de l'usager en se basant sur sa liste de RDVs :
  # - Si l'usager n'a pas de RDV, on retourne le domaine par défaut.
  # - Si tous les RDVs ont le même domaine, alors c'est le domaine de l'usager.
  # - Si les RDVs ont des domaines divers, on retourne le domaine du RDV le plus récent.
  #
  # Nous avions l'intention de faire en sorte que le domaine utilisé dans ces e-mails soit le
  # domaine de la page à partir duquel la demande a été faite, mais c'était techniquement complexe.
  # Voir : https://stackoverflow.com/questions/49328228
  def user_domain
    user = resource
    sign_up_domain_name = REDIS_CLIENT.get("user_session_domain:#{user.email}")
    sign_up_domain = Domain.find_by_name(sign_up_domain_name)
    return sign_up_domain if sign_up_domain

    user_rdvs = user.rdvs
    if user_rdvs.any?
      user_rdvs.order(created_at: :desc).first.domain
    else
      Domain::RDV_SOLIDARITES
    end
  end
end
