task file_attente: :environment do
  # Every 10 minutes, from 9am to 6pm
  FileAttenteJob.set(cron: "0/10 9,10,11,12,13,14,15,16,17,18 * * *").perform_later
end
