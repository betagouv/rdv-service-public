# frozen_string_literal: true

class Agent < AgentBase
  devise :invitable, :database_authenticatable, :trackable,
         :recoverable, :rememberable, :validatable, :confirmable, :async, validate_on_invite: true

  include DeviseTokenAuth::Concerns::ConfirmableSupport
  include DeviseTokenAuth::Concerns::UserOmniauthCallbacks

  include Outlook::Connectable
  include CanHaveTerritorialAccess
  include DeviseInvitable::Inviter
  include Agent::SearchConcern

  # Validation
  # Note about validation and Devise:
  # * Invitable#invite! creates the Agent without validation, but validates manually in advance (because we set validate_on_invite to true)
  # * it validates :email (the invite_key) specifically with Devise.email_regexp.
  validates :email, presence: true

  # This method is called when calling #current_agent on a controller action that is automatically generated
  # by the devise_token_auth gem. It can happen since these actions inherits from ApplicationController (see PR #1933).
  # We monkey-patch it for it not to raise.
  def self.dta_find_by(_attrs = {})
    nil
  end

  def remember_me # Override from Devise::rememberable to enable it by default
    super.nil? ? true : super
  end
end
