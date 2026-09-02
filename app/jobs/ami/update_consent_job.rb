class Ami::UpdateConsentJob < ApplicationJob
  queue_as :latency_30s

  def perform(fc_hash, consent_boolean)
    connection.post("/api/v1/consent/#{fc_hash}", { consent: consent_boolean })
  end

  private

  def connection
    @connection ||= AmiClient.new.connection
  end
end
