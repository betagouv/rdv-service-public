# frozen_string_literal: true

class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  belongs_to :rdvs_user
  has_one :rdv, through: :rdvs_user
  has_one :user, through: :rdvs_user

  validates :rdvs_user_id, uniqueness: true
  validates :first_name, :last_name, :email, presence: true
end
