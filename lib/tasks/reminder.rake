task send_reminder: :environment do
  # At 09:00:00am every day
  ReminderJob.set(cron: '0 9 * * *').perform_later
end
