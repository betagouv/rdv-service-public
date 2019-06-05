class Specialite < ApplicationRecord
  belongs_to :organisation
  has_many :pros
  has_many :motifs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, presence: true
end
