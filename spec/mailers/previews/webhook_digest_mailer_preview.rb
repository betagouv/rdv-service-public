class WebhookDigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    WebhookDigestMailer.weekly_digest(notification_email: WebhookExecution.pluck(:notification_email).compact_blank.first)
  end
end
