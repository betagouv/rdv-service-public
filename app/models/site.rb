class Site < ApplicationRecord
  belongs_to :organisation

  validates :name, :address, :telephone, :horaires, presence: true
end
