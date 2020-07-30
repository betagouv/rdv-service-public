task rdv_events_stats_mail: :environment do
  SendRdvEventsStatsMailJob.set(cron: "0 12 * * *").perform_later
end
