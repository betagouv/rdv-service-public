class Prescripteur < ApplicationRecord
  self.ignored_columns = %w[participation_id]

  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  has_one :participation, as: :created_by, dependent: :restrict_with_error
  has_one :rdv, through: :participation
  has_one :user, through: :participation

  validates :first_name, :last_name, :email, presence: true
end
