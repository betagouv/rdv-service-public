class WebhookDigestMailer < ApplicationMailer
  def weekly_digest(notification_email:, first_day:)
    @notification_email = notification_email
    @week = first_day..(first_day + 6.days)
    @endpoints = WebhookEndpoint.where(notification_email:)
    @executions = WebhookExecution.where(webhook_endpoint: endpoints, day: @week)
  end

  private

  class EndpointDigest
    def initialize(endpoint)
      @endpoint = endpoint
    end
  end
end
