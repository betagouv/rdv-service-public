class UserProfile < ApplicationRecord
  # Mixins
  include WebhookDeliverable

  # Relations
  belongs_to :organisation
  belongs_to :user

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  # Validations
  validates :user_id, uniqueness: { scope: :organisation }

  # Delegations
  delegate :territory, :territory_id, to: :organisation, allow_nil: true
end
