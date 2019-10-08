class Organisation < ApplicationRecord
  has_many :pros, dependent: :destroy
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy

  validates :name, presence: true
  validates :departement, presence: true, length: { is: 2 }
end
