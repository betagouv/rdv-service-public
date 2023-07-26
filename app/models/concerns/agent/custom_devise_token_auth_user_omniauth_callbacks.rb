# frozen_string_literal: true

# rubocop:disable all

# This is an override of the default concern : DeviseTokenAuth::Concerns::UserOmniauthCallbacks
# Changes :
# Add `&& !all_roles_intervenant?` condition to the included validations
module Agent::CustomDeviseTokenAuthUserOmniauthCallbacks
  extend ActiveSupport::Concern

  included do
    validates :email, presence: true, if: lambda { uid_and_provider_defined? && email_provider? && !all_roles_intervenant? }
    validates :email, :devise_token_auth_email => true, allow_nil: true, allow_blank: true, if: lambda { uid_and_provider_defined? && email_provider? && !all_roles_intervenant? }
    validates_presence_of :uid, if: lambda { uid_and_provider_defined? && !email_provider? && !all_roles_intervenant? }

    # only validate unique emails among email registration users
    validates :email, uniqueness: { case_sensitive: false, scope: :provider }, on: :create, if: lambda { uid_and_provider_defined? && email_provider? && !all_roles_intervenant? }

    # keep uid in sync with email
    before_save :sync_uid
    before_create :sync_uid
  end

  def all_roles_intervenant?
    @all_roles_intervenant ||= roles.present? && roles.to_a.all? { |role| role.access_level == "intervenant" }
  end

  protected

  def password_required?
    return false if all_roles_intervenant?
    super
  end

  def email_required?
    return false if all_roles_intervenant?
    super
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
