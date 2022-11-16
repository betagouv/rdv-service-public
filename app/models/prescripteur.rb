# frozen_string_literal: true

class Prescripteur < ApplicationRecord
  include FullNameConcern
  include PhoneNumberValidation::HasPhoneNumber

  belongs_to :rdv

  validates :rdv_id, uniqueness: true
  validates :first_name, :last_name, :email, presence: true
end
