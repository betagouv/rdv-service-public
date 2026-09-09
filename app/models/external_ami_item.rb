class ExternalAmiItem < ApplicationRecord
  belongs_to :rdv_plan

  validates :partner_id, :item_type, :item_id, presence: true
end
