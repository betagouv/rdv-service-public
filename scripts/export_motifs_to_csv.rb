# frozen_string_literal: true

puts "Nom;Type;Reservable en ligne ?;Ouvert au secrétariat ?;Suivi ?;RDV Collectif ?;Durée par défaut (en min);Category;Nom du service;Nom du territoire;Code du territoire"

Motif.joins(:organisation).all.each do |m|
  line = [m.name]
  line << m.location_type
  line << m.reservable_online
  line << m.secretariat?
  line << m.follow_up?
  line << m.collectif
  line << m.default_duration_in_min
  line << m.category
  line << m.service.name
  line << m.organisation.territory
  line << m.organisation.territory.departement_number
  puts line.join(";")
end
