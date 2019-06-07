class User < ApplicationRecord
  belongs_to :organisation, optional: true

  validates :last_name, :first_name, presence: true
end
