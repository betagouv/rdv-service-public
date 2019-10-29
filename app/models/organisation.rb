class Organisation < ApplicationRecord
  has_many :agents, dependent: :destroy
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy

  validates :name, presence: true
  validates :departement, presence: true, length: { is: 2 }
end
