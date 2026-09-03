class Ami::SendEventJob < ApplicationJob
  queue_as :latency_30s

  def perform(payload)
    fc_hash = payload[:recipient_fc_hash]

    if consent?(payload[:recipient_fc_hash])
      connection.put("/api/v2/event", payload)
    else
      UserAmiProfile.find_by(fc_hash:)&.update(notify_by_ami: false)
    end
  end

  private

  def consent?(fc_hash)
    connection.get("/api/v1/consent/#{fc_hash}").success?
  end

  def connection
    @connection ||= AmiClient.new.connection
  end
end
