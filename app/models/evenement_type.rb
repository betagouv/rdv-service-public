class EvenementType < ApplicationRecord
  belongs_to :motif
  has_one :organisation, through: :motif

  validates :name, :motif, :color, presence: true
end
