task send_file_attente: :environment do
  # Every 10 minutes, from 9am to 6pm, from monday to friday
  FileAttenteJob.set(cron: "0,10,20,30,40,50 9,10,11,12,13,14,15,16,17,18 ? * MON,TUE,WED,THU,FRI *").perform_later
end
