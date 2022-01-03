# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  has_paper_trail
  belongs_to :organisation

  validates :target_url, presence: true
  validates :secret, presence: true

  ALL_SUBSCRIPTIONS = %w[rdv absence plage_ouverture user user_profile organisation].freeze
end
