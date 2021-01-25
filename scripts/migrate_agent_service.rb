# USAGE:
# dry run: rails runner scripts/migrate_agent_service.rb https://gist.githubusercontent.com/xxx.csv SAPHA
# where SAPHA is a service short name

class AgentToServiceMigration
  attr_reader :agent, :service_target, :simulation

  def initialize(agent, service_target, simulation: true)
    @agent = agent
    @service_target = service_target
    @simulation = simulation
  end

  def migrate!
    Rails.logger.info "will #{simulation ? 'simulate ' : ''} migrate agent #{agent.id} (#{agent.full_name}) from service #{agent.service.short_name} to service #{service_target.short_name}..."
    agent.organisations.each { migrate_from_organisation(_1) }
  end

  def self.upsert_target_motif_memoized(motif_source, organisation, service_target)
    @results ||= {}
    key = "m#{motif_source.id}-o#{organisation.id}-s#{service_target.id}"
    return @results[key] if @results.key?(key)

    @results[key] = upsert_target_motif(motif_source, organisation, service_target)
  end

  def self.upsert_target_motif(motif_source, organisation, service_target)
    target_motif = Motif.where(organisation: organisation, service: service_target, name: motif_source.name).first
    if target_motif.nil?
      Rails.logger.warn "orga '#{organisation.name}';impossible de trouver un motif '#{motif_source.name}';dans le `service #{service_target.short_name}"
      return nil
    end
    target_motif
  end

  private

  def migrate_from_organisation(organisation)
    agent.plage_ouvertures.where(organisation: organisation)
      .each { migrate_plage_ouverture(_1, organisation) }
    agent.rdvs.where(organisation: organisation)
      .each { migrate_rdv(_1, organisation) }
  end

  def migrate_plage_ouverture(plage_ouverture, organisation)
    motifs_target = plage_ouverture.motifs.map { self.class.upsert_target_motif_memoized(_1, organisation, service_target) }
    return if motifs_target.any?(&:nil?)

    if simulation
      Rails.logger.info "would update PO #{plage_ouverture.id} with motifs #{motifs_target.pluck(:name).join(' - ')}"
    else
      plage_ouverture.update!(motifs: motifs_target)
    end
  end

  def migrate_rdv(rdv, organisation)
    motif_target = self.class.upsert_target_motif_memoized(rdv.motif, organisation, service_target)
    return if motif_target.nil?

    if simulation
      Rails.logger.info "would update RDV #{rdv.id} with motif #{motif_target.name}"
    else
      rdv.update!(motif: motif_target)
    end
  end
end

ActiveRecord::Base.logger.level = :warn
if ARGV[0] == "--perform"
  simulate = false
  csv_url = ARGV[1]
  service_short_name = ARGV[2]
else
  simulate = true
  csv_url, service_short_name = ARGV
end

emails = Typhoeus.get(csv_url).response_body.force_encoding("utf-8").split("\n")
service_target = Service.find_by_short_name!(service_short_name)
puts "service_target is #{service_target}"
email_agent_pairs = emails.map { [_1, Agent.where("email ILIKE unaccent(?)", "%#{_1}%").first] }

email_agent_pairs.select { _2.nil? }.each do |pair|
  puts "⚠️ agent with email #{pair[0]} not found"
end
agents = email_agent_pairs.map { _2 }.compact

agents_already_migrated = agents.select { _1.service == service_target }
puts "info: will skip #{agents_already_migrated.count} agents already migrated" if agents_already_migrated.any?

agents_to_migrate = agents.reject { _1.service == service_target }
puts "migrating #{agents_to_migrate.count} agents..."

agents_to_migrate.each do |agent|
  AgentToServiceMigration.new(agent, service_target, simulation: simulate).migrate!
end
