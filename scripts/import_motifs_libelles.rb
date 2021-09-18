# frozen_string_literal: true

require "csv"

url = ARGV[0]

puts "import from `#{url}`"
puts "#{MotifLibelle.count} libellé de motif avant import"

CSV.foreach(URI.open(url)) do |row|
  MotifLibelle.find_or_create_by(name: row[2], service_id: row[3])
end

puts "#{MotifLibelle.count} libellé de motif après import"
puts "Terminé"
