task update_plage_ouverture_expiration: :environment do
  # At 01:00:00am every day
  UpdatePlageOuverturesExpirationsJob.set(cron: '0 1 * * *').perform_later
end
