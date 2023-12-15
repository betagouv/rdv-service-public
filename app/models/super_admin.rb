class SuperAdmin < ApplicationRecord
  # Mixins
  include DeviseInvitable::Inviter

  devise :authenticatable

  ## -

  enum role: {
    super_admin: "super_admin",
    support: "support",
  }, _suffix: "member"

  def full_name
    "Équipe de RDV Service Public"
  end
end
