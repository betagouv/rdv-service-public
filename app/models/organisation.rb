class Organisation < ApplicationRecord
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy
  has_and_belongs_to_many :agents, -> { distinct }
  has_and_belongs_to_many :users, -> { distinct }

  validates :name, presence: true
  validates :departement, presence: true, length: { is: 2 }
end
