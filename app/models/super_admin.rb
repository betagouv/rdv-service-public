class SuperAdmin < ApplicationRecord
  # Mixins
  include DeviseInvitable::Inviter

  devise :authenticatable

  ## -

  def full_name
    "Équipe de RDV Service Public"
  end
end
