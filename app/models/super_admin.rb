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
end
