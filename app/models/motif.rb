class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :specialite
  has_many :evenement_types, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, :specialite, presence: true
end
