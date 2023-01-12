# frozen_string_literal: true

# Ce concern nous permet de définir le domaine à utiliser pour un⋅e usager⋅e dans les mailers Devise
module User::DeviseHasDomain
  extend ActiveSupport::Concern

  def domain
    if rdvs.any?
      rdvs.order(created_at: :desc).first.domain
    elsif sign_up_domain
      sign_up_domain
    else
      Domain::RDV_SOLIDARITES
    end
  end

  REDIS_FOR_SIGN_UP_DOMAIN = Redis.new(url: Rails.configuration.x.redis_url)

  def sign_up_domain=(domain)
    return if email.blank?

    REDIS_FOR_SIGN_UP_DOMAIN.set(redis_key_for_sign_up_domain, domain.id, ex: 12.hours.in_seconds)
  end

  def sign_up_domain
    return if email.blank?

    user_domain_id = REDIS_FOR_SIGN_UP_DOMAIN.get(redis_key_for_sign_up_domain)
    Domain.find(user_domain_id) if user_domain_id
  end

  private

  def redis_key_for_sign_up_domain
    "#{Rails.env}:user_session_domain:#{email}"
  end
end
