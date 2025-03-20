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

  def name_for_paper_trail(impersonated_agent: nil)
    return "[Admin] #{full_name} (super_admin_id=#{id})" if impersonated_agent.blank?

    "[Admin] #{full_name} (super_admin_id=#{id}) pour #{impersonated_agent.full_name} (agent_id=#{impersonated_agent.id})"
  end
end
