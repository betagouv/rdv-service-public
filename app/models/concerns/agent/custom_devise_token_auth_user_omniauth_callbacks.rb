# rubocop:disable all

# This is an override of the default concern : DeviseTokenAuth::Concerns::UserOmniauthCallbacks
# Changes :
# Add `&& !is_an_intervenant?` condition to the included validations
module Agent::CustomDeviseTokenAuthUserOmniauthCallbacks
  extend ActiveSupport::Concern

  included do
    validates :email, presence: true, if: lambda { uid_and_provider_defined? && email_provider? && !is_an_intervenant? }
    validates :email, :devise_token_auth_email => true, allow_nil: true, allow_blank: true, if: lambda { uid_and_provider_defined? && email_provider? && !is_an_intervenant? }
    validates_presence_of :uid, if: lambda { uid_and_provider_defined? && !email_provider? && !is_an_intervenant? }

    # only validate unique emails among email registration users
    validates :email, uniqueness: { case_sensitive: false, scope: :provider }, on: :create, if: lambda { uid_and_provider_defined? && email_provider? && !is_an_intervenant? }

    # keep uid in sync with email
    before_save :sync_uid
    before_create :sync_uid
  end

  def is_an_intervenant?
    # Intervenant is an agent with no email and only one role in one organisation (validation in AgentRole model)
    # TODO: Avoir une réflexion globale sur l'authentification des agents et des users.
    # TODO: Penser à la mise en place de nouveaux models UserAccount et AgentAccount
    @is_an_intervenant ||= roles.present? && roles.one? && roles.first.access_level == "intervenant"
  end

  protected

  def password_required?
    super && !is_an_intervenant?
  end

  def email_required?
    # Cette méthode est aussi implémentée par Devise::Models::Validatable, et utilisée pour vérifier les confirmations de mot de passe
    super && !is_an_intervenant?
  end

  def uid_and_provider_defined?
    defined?(provider) && defined?(uid)
  end

  def email_provider?
    provider == 'email'
  end

  def sync_uid
    unless self.new_record?
      return if devise_modules.include?(:confirmable) && !@bypass_confirmation_postpone && postpone_email_change?
    end
    self.uid = email if uid_and_provider_defined? && email_provider?
  end
end
