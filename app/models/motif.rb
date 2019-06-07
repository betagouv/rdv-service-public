class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :specialite
  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :organisation, :specialite, presence: true
end
