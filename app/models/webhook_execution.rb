class WebhookExecution < ApplicationRecord
  belongs_to :webhook_endpoint, inverse_of: :webhook_executions

  def self.record_execution!(webhook_endpoint_id:, http_code:)
    execution_log = find_or_create_by!(webhook_endpoint_id:, http_code:, day: Time.zone.today)
    increment_counter(:counter, execution_log.id) # rubocop:disable Rails/ SkipsModelValidations
  end

  def successful?
    http_code.between?(200, 299)
  end

  def failed?
    !successful?
  end
end
