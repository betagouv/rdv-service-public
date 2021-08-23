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
csv = CSV.new(URI.parse(file).open, col_sep: ";", encoding: "ISO-8859-1")
csv.each do |row|
  ligne += 1
  agent = Agent.find_by(email: row[4])
  unless agent
    puts "#{ligne} - Agent non trouvé #{row[4]}"
    next
  end

  begin
    absence_params = {
      agent: agent,
      title: row[5],
      organisation: organisation,
      first_day: Date.parse(row[0]),
      start_time: Time.zone.parse(row[1]).to_time,
      end_day: Date.parse(row[2]),
      end_time: Time.zone.parse(row[3]).to_time
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
