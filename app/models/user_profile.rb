# frozen_string_literal: true

class UserProfile < ApplicationRecord
  # Mixins
  include WebhookDeliverable

  # Attributes

  # Relations
  belongs_to :organisation
  belongs_to :user

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  # Validations
  validates :user_id, uniqueness: { scope: :organisation }
end
