class SendRdvEventsStatsMailJob < ApplicationJob
  def perform
    Admins::SystemMailer.rdv_events_stats.deliver_later
  end
end
