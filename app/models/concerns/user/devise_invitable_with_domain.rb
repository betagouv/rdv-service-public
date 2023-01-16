# frozen_string_literal: true

# Ce concern nous permet de définir le domaine à utiliser pour un⋅e usager⋅e dans les mailers Devise
module User::DeviseInvitableWithDomain
  extend ActiveSupport::Concern

  # Overriding this method from devise_invitable so we can pass in a domain
  def invite!(domain: nil, invited_by: nil, options: {})
    self.sign_up_domain = domain if domain
    super(invited_by, options)
  end

  REDIS_FOR_SIGN_UP_DOMAIN = Redis.new(url: Rails.configuration.x.redis_url)

  def sign_up_domain=(domain)
    return if email.blank?

    REDIS_FOR_SIGN_UP_DOMAIN.set(redis_key_for_sign_up_domain, domain.id, ex: 12.hours.in_seconds)
  end

  private

  def sign_up_domain
    return if email.blank?

    user_domain_id = REDIS_FOR_SIGN_UP_DOMAIN.get(redis_key_for_sign_up_domain)
    Domain.find(user_domain_id) if user_domain_id
  end

  def redis_key_for_sign_up_domain
    "#{Rails.env}:user_session_domain:#{email}"
  end
end
