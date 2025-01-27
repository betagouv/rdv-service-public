class WebhookExecution < ApplicationRecord
  belongs_to :webhook_endpoint

  def self.record_execution!(webhook_endpoint_id:, http_code:)
    execution_log = find_or_create_by!(webhook_endpoint_id:, http_code:, day: Time.zone.today)
    increment_counter(:counter, execution_log.id) # rubocop:disable Rails/ SkipsModelValidations
  end
end
