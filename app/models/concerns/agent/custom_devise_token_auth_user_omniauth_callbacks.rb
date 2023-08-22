# frozen_string_literal: true

# rubocop:disable all

# This is an override of the default concern : DeviseTokenAuth::Concerns::UserOmniauthCallbacks
# Changes :
# Add `&& has_a_role_with_account_access?` condition to the included validations
module Agent::CustomDeviseTokenAuthUserOmniauthCallbacks
  extend ActiveSupport::Concern

  included do
    validates :email, presence: true, if: lambda { uid_and_provider_defined? && email_provider? && has_a_role_with_account_access? }
    validates :email, :devise_token_auth_email => true, allow_nil: true, allow_blank: true, if: lambda { uid_and_provider_defined? && email_provider? && has_a_role_with_account_access? }
    validates_presence_of :uid, if: lambda { uid_and_provider_defined? && !email_provider? && has_a_role_with_account_access? }

    # only validate unique emails among email registration users
    validates :email, uniqueness: { case_sensitive: false, scope: :provider }, on: :create, if: lambda { uid_and_provider_defined? && email_provider? && has_a_role_with_account_access? }

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

  # TODO: voir si on peut se passer de cette méthode
  def has_a_role_with_account_access?
    roles.any? { |r| !r.intervenant?  }
  end

  protected

  def password_required?
    super && has_a_role_with_account_access?
  end

  def email_required?
    # Cette méthode est aussi implémentée par Devise::Models::Validatable, et utilisée pour vérifier les confirmations de mot de passe
    super && has_a_role_with_account_access?
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
