class SuperAdmin < ApplicationRecord
  # Mixins
  include DeviseInvitable::Inviter

  devise :authenticatable

  ## -

  def full_name
    "Équipe de RDV Service Public"
  end

  def self.anonymized_column_names
    %w[email]
  end

  def self.non_anonymized_column_names
    %w[id created_at updated_at]
  end
end
