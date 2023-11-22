class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  belongs_to :participation
  has_one :rdv, through: :participation
  has_one :user, through: :participation

  validates :participation_id, uniqueness: true
  validates :first_name, :last_name, :email, presence: true
end
