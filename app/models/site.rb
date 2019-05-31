class Site < ApplicationRecord
  belongs_to :organisation

  validates :name, :address, presence: true
end
