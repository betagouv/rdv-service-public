class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber
  include Anonymizable

  belongs_to :participation
  has_one :rdv, through: :participation
  has_one :user, through: :participation

  validates :participation_id, uniqueness: true
  validates :first_name, :last_name, :email, presence: true

  def self.personal_data_column_names
    %w[first_name last_name email phone_number phone_number_formatted]
  end

  def self.non_personal_data_column_names
    %w[id participation_id user_id created_at updated_at]
  end
end
