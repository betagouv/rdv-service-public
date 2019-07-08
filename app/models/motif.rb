class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :specialite
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :color, :default_duration_in_min, presence: true
end
