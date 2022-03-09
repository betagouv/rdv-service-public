# frozen_string_literal: true

# We declare the following queues in the code:
# :cron     used in CronJob
# :webhook  used in WebhookJob
# :mailers  used in ApplicationMailer
# :devise   used in CustomDeviseMailer
# :sms      used in ApplicationSms
#
# Additionally, we declare the two following queues for lower priority jobs (e.g. Reminders)
# :mailers_low
# :sms_low
Delayed::Worker.queue_attributes = {
  mailers_low: { priority: 10 }, # Higher numbers have lower priority.
  sms_low: { priority: 10 }
}
