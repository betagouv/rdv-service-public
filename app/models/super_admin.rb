# frozen_string_literal: true

class SuperAdmin < ApplicationRecord
  include DeviseInvitable::Inviter

  devise :authenticatable

  def full_name
    "Équipe technique de RDV-Solidarités"
  end
end
