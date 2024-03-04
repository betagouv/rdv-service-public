# Ce concern nous permet de définir le domaine à utiliser pour un⋅e usager⋅e dans les mailers Devise
module User::DeviseInvitableWithDomain
  extend ActiveSupport::Concern

  # Overriding this method from devise_invitable so we can pass in a domain
  def invite!(domain: nil, invited_by: nil, options: {})
    self.sign_up_domain = domain if domain
    super(invited_by, options)
  end

  def sign_up_domain=(domain)
    return if email.blank?

    Redis.with_connection do |redis|
      redis.set(redis_key_for_sign_up_domain, domain.id, ex: 6.months.in_seconds)
    end
  end

  private

  def sign_up_domain
    return if email.blank?

    user_domain_id = Redis.with_connection { |redis| redis.get(redis_key_for_sign_up_domain) }
    Domain.find(user_domain_id) if user_domain_id
  end

  def redis_key_for_sign_up_domain
    "#{Rails.env}:user_session_domain:#{email}"
  end
end
