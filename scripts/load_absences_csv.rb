# frozen_string_literal: true

require "open-uri"
require "csv"

organisation_id = ARGV[0]
file = ARGV[1]

unless organisation_id.present? && file.present?
  puts "USAGER: rails runner scripts/load_absence_csv.rb <organisation_id> <csv_file_url>"
  puts "  look at ngrok (ngrok.com) to share csv file from your computer"
  exit 1
end

organisation = Organisation.find(organisation_id)
puts "Import des absences à partir du fichier #{file} pour l'organisation #{organisation.name}"

ligne = 0
CSV.foreach(URI.parse(file).open, col_sep: ";", headers: true, encoding: "ISO-8859-1") do |row|
  ligne += 1
  agent = Agent.find_by(email: row["agent_ID"])
  unless agent
    puts "#{ligne} - Agent non trouvé #{row['agent_ID']}"
    next
  end

  begin
    absence_params = {
      agent: agent,
      title: row["Name"],
      organisation: organisation,
      first_day: Date.parse(row["first_day"]),
      start_time: Time.zone.parse(row["start_time"]).to_time,
      end_day: Date.parse(row["end_day"]),
      end_time: Time.zone.parse(row["end_time"]).to_time
    }
  rescue StandardError
    puts "#{ligne} - erreur d'analyse de la ligne"
    next
  end
  if Absence.exists?(absence_params)
    puts "#{ligne} - absence existante pour la ligne"
    next
  end
  absence = Absence.new(absence_params)
  if absence.save
    puts "#{ligne} - Absence crée pour la ligne"
  else
    puts "#{ligne} - errors : #{absence.errors.full_messages.join(',')}"
  end
end
