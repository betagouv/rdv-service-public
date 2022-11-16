# frozen_string_literal: true

ActiveRecord::Base.logger = nil
# permanences = JSON.load_file("/tmp/uploads/permanences.json")
permanences = JSON.load_file("tmp/permanences.json")

permanences.each do |permanence|
  organisation = Organisation.find_by(external_id: permanence["structureId"])
  next unless organisation

  # Ne pas importer des nouveaux lieux si ils ont déjà été configurés manuellement
  next if organisation.lieux.count >= 2

  matching_lieu = organisation.lieux.find do |lieu|
    lieu.address.downcase.gsub(/[^0-9a-z]/, "").start_with?(permanence["adresse"].downcase.gsub(/[^0-9a-z]/, ""))
  end

  # Ne pas importer le lieu de permanence s'il existe déjà
  next if matching_lieu

  puts "Nouveau lieu potentiel pour #{organisation.name} :"
  puts "adresse de permanence #{permanence['adresse']}"
  puts "adresses de lieux #{organisation.lieux.map(&:address)}"
end
