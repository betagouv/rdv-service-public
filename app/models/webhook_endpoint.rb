# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail
  belongs_to :organisation

  # Validations
  validates :target_url, presence: true, uniqueness: { scope: :organisation_id }
  validates :secret, presence: true

  ALL_SUBSCRIPTIONS = %w[
    rdv absence plage_ouverture user user_profile organisation motif lieu agent agent_role referent_assignation
  ].freeze

  def trigger_for_all_subscribed_resources
    subscriptions.each do |subscription|
      if subscription == "organisation"
        trigger_for(organisation)
      else
        records = organisation.send(subscription.pluralize)
        records.each { |record| trigger_for(record) }
      end
    end
  end

  def trigger_for(record)
    WebhookJob.perform_later(record.generate_webhook_payload(:created), id)
  end
end
