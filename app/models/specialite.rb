class Specialite < ApplicationRecord
  belongs_to :organisation
  has_many :pros, dependent: :nullify
  has_many :motifs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, presence: true
end
