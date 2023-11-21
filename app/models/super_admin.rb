class SuperAdmin < ApplicationRecord
  # Mixins
  has_paper_trail
  include DeviseInvitable::Inviter

  devise :authenticatable

  ## -

  def full_name
    "Équipe de RDV Service Public"
  end
end
