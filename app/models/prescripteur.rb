class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  has_many :participations, as: :created_by, dependent: :restrict_with_error
  has_many :rdvs, through: :participations
  has_many :users, through: :participations

  validates :first_name, :last_name, :email, presence: true
end
