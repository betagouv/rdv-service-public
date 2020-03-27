class Webhook < ApplicationRecord
  has_paper_trail
  belongs_to :organisation

  validates :endpoint, presence: true
end
