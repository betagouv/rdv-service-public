class EvenementType < ApplicationRecord
  belongs_to :motif
  has_one :organisation, through: :motif
  has_many :rdvs

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :motif, :color, :default_duration_in_min, presence: true
end
