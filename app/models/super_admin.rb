class SuperAdmin < ApplicationRecord
  include DeviseInvitable::Inviter

  def full_name
    "Équipe technique de RDV-Solidarités"
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :omniauthable, omniauth_providers: [:github]
end
