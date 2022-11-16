# frozen_string_literal: true

# permanences = JSON.load_file("/tmp/uploads/permanences.json")
permanences = JSON.load_file("tmp/permanences.json")

permanences.each do |permanence|
  organisation = Organisation.find_by(external_id: permanence["structureId"])
  next unless organisation

  puts "Pour #{organisation.name}"
  puts "adresse de permanence #{permanence['adresse']}"
  puts "adresses de lieux #{organisation.lieux.map(&:address)}"
end
