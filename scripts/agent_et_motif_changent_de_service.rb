# rails runner scripts/agent-et-motif-changent-de-service.rb

ID_ORGANISATION = 1
IDS_SERVICE_SOURCE = [1, 2].freeze
ID_SERVICE_DESTINATION = 4

services_source = Service.where(id: IDS_SERVICE_SOURCE)
service_destination = Service.find(ID_SERVICE_DESTINATION)
organisation = Organisation.find(ID_ORGANISATION)

puts "Hello !"
puts "Déplace les agents et les motifs des services #{services_source.map(&:name).join(', ')} vers le service #{service_destination.name}"

Agent.transaction do
  puts "Déplacement des motifs:"
  Motif.where(organisation_id: ID_ORGANISATION, service: services_source).each do |motif|
    puts motif.name.to_s
    new_motif = motif.dup
    new_motif.organisation_id = ID_ORGANISATION
    new_motif.service_id = ID_SERVICE_DESTINATION
    next if new_motif.save

    puts "Erreur: #{new_motif.errors.full_messages.to_sentence}. Essayons en changeant le nom."
    new_motif.name += "*"
    new_motif.save!
  end

  puts "Déplacement des agents:"
  organisation.agents.each do |agent|
    puts agent.full_name.to_s
    agent.update_column(:service_id, ID_SERVICE_DESTINATION)
  end
  puts "Terminé"
end
