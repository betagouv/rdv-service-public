class User < ApplicationRecord
  belongs_to :organisation, optional: true

  validates :last_name, :first_name, presence: true
  validates :email, format: { with: Devise.email_regexp }, uniqueness: { case_sensitive: false, scope: :organisation }
end
