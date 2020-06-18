class SuperAdmin < ApplicationRecord
  include DeviseInvitable::Inviter

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :omniauthable, omniauth_providers: [:github, :franceconnect]
end
