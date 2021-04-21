# rails runner scripts/agent-et-motif-changent-de-service.rb

ID_ORGANISATION = 1
IDS_SERVICE_SOURCE = [1, 2]
ID_SERVICE_DESTINATION = 4

services_source = Service.where(id: IDS_SERVICE_SOURCE)
service_destination = Service.find(ID_SERVICE_DESTINATION)
organisation = Organisation.find(ID_ORGANISATION)

puts "Hello !"
puts "Déplace les agents et les motifs des services #{services_source.map(&:name).join(", ")} vers le service #{service_destination.name}"

Agent.transaction do
  Motif.where(organisation_id: ID_ORGANISATION, service: services_source).each do |motif|
    new_motif = motif.dup
    new_motif.organisation_id = ID_ORGANISATION
    new_motif.service_id = ID_SERVICE_DESTINATION
    unless new_motif.save
      puts "error ! on suppose que le nom existe déjà"
      new_motif.name += "*"
      new_motif.save!
    end
  end

  organisation.agents.each do |agent|
    agent.update_column(:service_id, ID_SERVICE_DESTINATION)
  end

end
