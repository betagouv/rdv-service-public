# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail
  belongs_to :organisation

  # Validations
  validates :target_url, presence: true
  validates :secret, presence: true

  ALL_SUBSCRIPTIONS = %w[rdv absence plage_ouverture user user_profile organisation].freeze
end
