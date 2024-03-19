class ReferentAssignation < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable

  # Relations
  belongs_to :user
  belongs_to :agent

  has_many :organisations, through: :user
  has_many :webhook_endpoints, through: :organisations

  # Validations
  validates :user_id, uniqueness: { scope: :agent }
end
