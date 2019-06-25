class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :specialite
  has_many :evenement_types, dependent: :destroy
  has_and_belongs_to_many :plage_ouvertures

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, :specialite, presence: true
end
