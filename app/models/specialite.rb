class Specialite < ApplicationRecord
  has_many :pros, dependent: :nullify
  has_many :motifs, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
