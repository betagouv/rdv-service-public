class EvenementType < ApplicationRecord
  belongs_to :motif
  has_one :organisation, through: :motif

  validates :name, :motif, :color, :default_duration_in_min, presence: true
end
