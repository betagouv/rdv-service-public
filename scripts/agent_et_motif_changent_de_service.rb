# frozen_string_literal: true

# rails runner scripts/agent_et_motif_changent_de_service.rb ID_ORGA ID_SERVICE_SOURCE ID_DESTINATION

ID_ORGANISATION = ARGV[0]
ID_SERVICE_SOURCE = ARGV[1]
ID_SERVICE_DESTINATION = ARGV[2]
dry_run = ARGV[3].blank?

service_source = Service.find(ID_SERVICE_SOURCE)
service_destination = Service.find(ID_SERVICE_DESTINATION)
organisation = Organisation.find(ID_ORGANISATION)

puts "Hello !"
puts "Running in dry run!" if dry_run
puts "Déplace les agents et les motifs du service #{service_source.name} vers le service #{service_destination.name}"

Agent.transaction do
  puts "Déplacement des motifs:"
  Motif.where(organisation_id: ID_ORGANISATION, service: service_source).each do |motif|
    puts motif.name.to_s
    new_motif = motif.dup
    new_motif.organisation_id = ID_ORGANISATION
    new_motif.service_id = ID_SERVICE_DESTINATION

    next if dry_run

    unless new_motif.save
      puts "Erreur: #{new_motif.errors.full_messages.to_sentence}. Essayons en changeant le nom."
      new_motif.name += "*"
      new_motif.save!
    end

    puts " avant - PO nouveau motif: #{new_motif.plage_ouvertures.count} - PO ancien motif: #{motif.plage_ouvertures.count}"
    new_motif.plage_ouvertures = motif.plage_ouvertures
    motif.plage_ouvertures = []
    puts " après - PO nouveau motif: #{new_motif.plage_ouvertures.count} - PO ancien motif: #{motif.plage_ouvertures.count}"

    puts "RDV nouveau motif: #{new_motif.rdvs.count} - RDV ancien motif: #{motif.rdvs.count}"
    motif.rdvs.each do |rdv|
      rdv.update_column(:motif_id, new_motif.id)
    end
    puts "RDV nouveau motif: #{new_motif.rdvs.count} - RDV ancien motif: #{motif.rdvs.count}"

    puts "archiving motif"
    motif.destroy_or_archive
  end

  puts "Déplacement des agents:"
  organisation.agents.where(service: service_source).each do |agent|
    puts agent.full_name.to_s
    next if dry_run

    agent.update_column(:service_id, ID_SERVICE_DESTINATION)
  end
  puts "Terminé"
end
