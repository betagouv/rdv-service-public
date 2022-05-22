# frozen_string_literal: true

require "optparse"

params = { dry_run: true }
OptionParser.new do |opt|
  opt.on("-o", "--organisation ORGANISATION_ID") { |o| params[:organisation_id] = o }
  opt.on("-s", "--service-source SERVICE_SOURCE_ID") { |o| params[:service_source_id] = o }
  opt.on("-d", "--service-destination SERVICE_DESTINATION_ID") { |o| params[:service_destination_id] = o }
  opt.on("-a", "--agent AGENT_ID") { |o| params[:agent_id] = o }
  opt.on("-e", "--execute") { |_o| params[:dry_run] = false }
end.parse!

unless (%i[organisation_id service_source_id service_destination_id] - params.keys).empty?
  puts "Le paramètre de l'organisation, du service source et celui du service destination sont obligatoire"
  exit(-1)
end

# Ces recherches sont surtout un moyen de vérifier si les paramètres
# données sont correct.
service_source = Service.find(params[:service_source_id])
service_destination = Service.find(params[:service_destination_id])
organisation = Organisation.find(params[:organisation_id])
agent = Agent.find(params[:agent_id]) if params[:agent_id].present?

puts "Hello !"
puts "Running in dry run!" if params[:dry_run]
msg = "Déplace"
msg += if agent
         " l'agents #{agent.full_name}"
       else
         " les agents"
       end
msg += " et les motifs du service #{service_source.name} vers le service #{service_destination.name}"
puts msg

Agent.transaction do
  puts "Déplacement des motifs:"
  Motif.where(organisation_id: params[:organiation_id], service: service_source).each do |motif|
    puts motif.name.to_s
    new_motif = motif.dup
    new_motif.organisation_id = params[:organisation_id]
    new_motif.service_id = params[:service_destination_id]

    next if params[:dry_run]

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

    puts "soft deleting motif"
    motif.soft_delete
  end

  puts "Déplacement des agents:"
  agents = organisation.agents.where(service: service_source)
  if params[:agent_id].present?
    agents = agents.where(id: params[:agent_id])
  end
  agents.each do |agent|
    puts agent.full_name.to_s
    next if params[:dry_run]

    agent.update_column(:service_id, params[:service_destination_id])
  end
  puts "Terminé"
end
