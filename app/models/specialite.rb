class Specialite < ApplicationRecord
  belongs_to :organisation
  has_many :pros

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, presence: true
end
