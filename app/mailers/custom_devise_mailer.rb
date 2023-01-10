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

  REDIS_FOR_USER_DOMAIN = Redis.new(url: Rails.configuration.x.redis_url)
  REDIS_USER_DOMAIN_KEY_PREFIX = "#{Rails.env}:user_session_domain:".freeze

  def self.save_user_domain(email:, domain:)
    REDIS_FOR_USER_DOMAIN.set("#{REDIS_USER_DOMAIN_KEY_PREFIX}#{email}", domain.id, ex: 12.hours.in_seconds)
  end

  def self.get_user_domain(email:)
    user_domain_id = REDIS_FOR_USER_DOMAIN.get("#{REDIS_USER_DOMAIN_KEY_PREFIX}#{email}")
    Domain.find_by_id(user_domain_id)
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
    sign_up_domain = self.class.get_user_domain(email: resource.email)
    return sign_up_domain if sign_up_domain

    user_rdvs = resource.rdvs
    if user_rdvs.any?
      user_rdvs.order(created_at: :desc).first.domain
    else
      Domain::RDV_SOLIDARITES
    end
  end
end
