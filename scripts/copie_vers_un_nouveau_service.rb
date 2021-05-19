# frozen_string_literal: true

# rails runner scripts/copie-vers-un-nouveau-service.rb

IDS_SERVICE_SOURCE = [5, 7].freeze
ID_SERVICE_DESTINATION = 22

services_source = Service.where(id: IDS_SERVICE_SOURCE)
service_destination = Service.find(ID_SERVICE_DESTINATION)

puts "Hello !"
puts "Copie des libellées de motifs des services #{services_source.map(&:name).join(', ')} vers le service #{service_destination.name}"

libelle_motifs_source = MotifLibelle.where(service_id: IDS_SERVICE_SOURCE)
libelle_motifs_source.each do |source|
  puts "copie du libelle #{source.name}"
  MotifLibelle.find_or_create_by!(name: source.name, service: service_destination)
end

puts "#{libelle_motifs_source.count} libellés motif source"
puts "#{MotifLibelle.where(service: service_destination).count} libellés motif créés"

# NOTE : attention, il peut y avoir des doublons. Dans mon exemple de test, il y a RDV Collectif dans la PMI ET dans le Social. À l'arrivé on se retrouve avec un seul motif RDV Collectif
