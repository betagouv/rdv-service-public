# USAGE:
# dry run: rails runner scripts/agents_service_migration.rb https://gist.githubusercontent.com/agents.csv https://gist.githubusercontent.com/mapping.csv SAPHA
# where SAPHA is a service short name

require "csv"

class AgentServiceMigration
  attr_reader :agent, :service_target, :simulation, :motifs_mapping

  def initialize(agent, service_target, simulation: true, motifs_mapping: {})
    @agent = agent
    @service_target = service_target
    @simulation = simulation
    @motifs_mapping = motifs_mapping
  end

  def migrate!
    Rails.logger.info "will #{simulation ? 'simulate ' : ''} migrate agent #{agent.id} (#{agent.full_name}) from service #{agent.service.short_name} to service #{service_target.short_name}..."
    agent.organisations.each { migrate_from_organisation(_1) }
  end

  def self.upsert_target_motif_memoized(motif_source, organisation, service_target, motifs_mapping)
    @results ||= {}
    key = "m#{motif_source.id}-o#{organisation.id}-s#{service_target.id}"
    return @results[key] if @results.key?(key)

    @results[key] = upsert_target_motif(motif_source, organisation, service_target, motifs_mapping)
  end

  def self.upsert_target_motif(motif_source, organisation, service_target, motifs_mapping)
    mapped_name = motifs_mapping.fetch([organisation.name, motif_source.name], motif_source.name)
    target_motif = Motif.where(organisation: organisation, service: service_target, name: mapped_name).first
    if target_motif.nil?
      Rails.logger.warn "orga '#{organisation.name}';impossible de trouver un motif '#{mapped_name}';dans le `service #{service_target.short_name}"
      return nil
    end
    target_motif
  end

  private

  def migrate_from_organisation(organisation)
    agent.plage_ouvertures.where(organisation: organisation).each(&:destroy!)
    agent.rdvs.where(organisation: organisation).each { migrate_rdv(_1, organisation) }
  end

  def migrate_plage_ouverture(plage_ouverture, organisation)
    motifs_target = plage_ouverture.motifs.map { self.class.upsert_target_motif_memoized(_1, organisation, service_target, motifs_mapping) }
    return if motifs_target.any?(&:nil?)

    if simulation
      Rails.logger.info "would update PO #{plage_ouverture.id} with motifs #{motifs_target.pluck(:name).join(' - ')}"
    else
      plage_ouverture.update!(motifs: motifs_target)
    end
  end

  def migrate_rdv(rdv, organisation)
    motif_target = self.class.upsert_target_motif_memoized(rdv.motif, organisation, service_target, motifs_mapping)
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
  agents_csv_url = ARGV[1]
  mapping_csv_url = ARGV[2]
  service_short_name = ARGV[3]
else
  simulate = true
  agents_csv_url, mapping_csv_url, service_short_name = ARGV
end

emails = Typhoeus.get(agents_csv_url).response_body.force_encoding("utf-8").split("\n")
mapping = CSV.new(
  Typhoeus.get(mapping_csv_url).response_body.force_encoding("utf-8").to_s, col_sep: ";", headers: true
).map { [[_1["organisation_name"], _1["name_source"]], _1["name_target"]] }.to_h
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
  AgentServiceMigration.new(agent, service_target, simulation: simulate, motifs_mapping: mapping).migrate!
end

# rails runner scripts/agents_service_migration.rb https://gist.githubusercontent.com/adipasquale/7db57c9998dbc5828f1969ad536387d3/raw/03b3d0f5131c4e710a3300227ce3f88f1d82346f/77sapha.csv https://gist.githubusercontent.com/adipasquale/fb4c1797381d447753cf297cf7d839c6/raw/f4e2f0e1b692ba0def7004e4c420c9d3451618ed/mapping.csv SAPHA
