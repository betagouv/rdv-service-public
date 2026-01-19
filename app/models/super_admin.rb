class SuperAdmin < ApplicationRecord
  # Mixins
  has_paper_trail
  include DeviseInvitable::Inviter
  include FullNameConcern

  # Attributes
  enum :role, {
    legacy_admin: "legacy_admin",
    support: "support",
  }, suffix: "member"

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true

  devise :authenticatable

  def name_for_paper_trail(impersonated: nil)
    return "[Admin] #{full_name}" if impersonated.blank?

    "[Admin] #{full_name} pour #{impersonated.full_name}"
  end

  # This method is called when calling #current_super_admin on a controller action that is automatically generated
  # by the devise_token_auth gem. It can happen since these actions inherits from ApplicationController (see PR #1933).
  # We monkey-patch it for it not to raise.
  def self.dta_find_by(_attrs = {})
    nil
  end
end
