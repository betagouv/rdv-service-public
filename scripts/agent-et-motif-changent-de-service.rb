# rails runner scripts/agent-et-motif-changent-de-service.rb

ORGANISATION_ID = 1
IDS_SERVICE_SOURCE = [1, 2]
ID_SERVICE_DESTINATION = 4

services_source = Service.where(id: IDS_SERVICE_SOURCE)
service_destination = Service.find(ID_SERVICE_DESTINATION)

puts "Hello !"
puts "Déplace les agents et les motifs des services #{services_source.map(&:name).join(", ")} vers le service #{service_destination.name}"

Agent.transaction do
  Motif.transaction do
    Motif.where(organisation_id: ORGANISATION_ID, service: services_source).each do |motif|
      new_motif = Motif.new(name: motif.name,
                            color: motif.color,
                            default_duration_in_min: motif.default_duration_in_min,
                            organisation_id: ORGANISATION_ID,
                            reservable_online: motif.reservable_online,
                            min_booking_delay: motif.min_booking_delay,
                            max_booking_delay: motif.max_booking_delay,
                            deleted_at: motif.deleted_at,
                            service_id: ID_SERVICE_DESTINATION,
                            restriction_for_rdv: motif.restriction_for_rdv,
                            instruction_for_rdv: motif.instruction_for_rdv,
                            for_secretariat: motif.for_secretariat,
                            location_type: motif.location_type,
                            follow_up: motif.follow_up,
                            visibility_type: motif.visibility_type,
                            sectorisation_level: motif.sectorisation_level)
      unless new_motif.save
        puts "error ! on suppose que le nom existe déjà"
        new_motif.name += "*"
        new_motif.save!
      end
    end

    Agent.joins(:roles).where("agents_organisations.organisation_id": ORGANISATION_ID, service: services_source).each do |agent|
      agent.service = service_destination
      agent.save!(validate: false)
    end

  end
end
