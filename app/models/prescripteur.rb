class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  INTERNE = "interne".freeze

  has_one :participation, as: :created_by, dependent: :restrict_with_error
  has_one :rdv, through: :participation
  has_one :user, through: :participation

  validates :first_name, :last_name, :email, presence: true

  encrypts :token, deterministic: true

  before_save :set_token

  def name_for_paper_trail
    "[Prescripteur] #{full_name}"
  end

  def set_token
    return if token

    self.token = SecureRandom.hex(48)
  end
end
