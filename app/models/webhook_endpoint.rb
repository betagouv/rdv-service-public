# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  has_paper_trail
  belongs_to :organisation

  validates :target_url, presence: true
  validates :secret, presence: true

  TRIGGERING_RESOURCES = %w[rdv absence plage_ouverture user user_profile].freeze
end
