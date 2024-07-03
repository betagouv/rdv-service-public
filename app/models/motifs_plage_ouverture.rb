class MotifsPlageOuverture < ApplicationRecord
  belongs_to :motif
  belongs_to :plage_ouverture

  validates :motif_id, uniqueness: { scope: :plage_ouverture_id }
end
