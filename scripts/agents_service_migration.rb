# USAGE:
# dry run: rails runner scripts/agents_service_migration.rb https://gist.githubusercontent.com/agents.csv https://gist.githubusercontent.com/mapping.csv SAPHA
# where SAPHA is a service short name

require "csv"

class AgentServiceMigration
  include PlageOuverturesHelper
  attr_reader :agent, :service_target, :simulation, :motifs_mapping

  def l(*args)
    I18n.l(*args)
  end

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
    mapped_name = motifs_mapping.fetch([organisation.name, motif_source.name.strip], motif_source.name.gsub("service social", "service SAPHA").strip)
    target_motif = Motif.where(organisation: organisation, service: service_target, name: mapped_name, location_type: motif_source.location_type).first
    return target_motif if target_motif.present?

    Rails.logger.warn "orga '#{organisation.name}'; service #{service_target.short_name}; Motif '#{motif_source.name} => #{mapped_name}' créé"
    Motif.create!(
      organisation: organisation,
      service: service_target,
      name: mapped_name,
      **motif_source.attributes.symbolize_keys.slice(
        :name, :color, :default_duration_in_min, :reservable_online,
        :min_booking_delay, :max_booking_delay, :restriction_for_rdv,
        :instruction_for_rdv, :for_secretariat, :location_type, :follow_up,
        :visibility_type, :sectorisation_level
      )
    )
  end

  private

  def migrate_from_organisation(organisation)
    pos = agent.plage_ouvertures.where(organisation: organisation)
    pos.each { migrate_plage_ouverture(_1, organisation) }
    rdvs = agent.rdvs.where(organisation: organisation)
    rdvs.each { migrate_rdv(_1, organisation) }
    Rails.logger.warn("agent migré #{agent.full_name} - #{pos.count} POs - #{rdvs.count} RDVs")
    agent.update_columns(service_id: service_target.id) unless simulation
  end

  def migrate_plage_ouverture(plage_ouverture, organisation)
    return if plage_ouverture.motifs.empty?

    motifs_target = plage_ouverture.motifs.map { self.class.upsert_target_motif_memoized(_1, organisation, service_target, motifs_mapping) }
    if simulation
      Rails.logger.info "would update PO #{plage_ouverture.id} with motifs #{motifs_target.pluck(:name).join(' - ')}"
    else
      plage_ouverture.update!(motifs: motifs_target, active_warnings_confirm_decision: true)
    end
  end

  def migrate_rdv(rdv, organisation)
    motif_target = self.class.upsert_target_motif_memoized(rdv.motif, organisation, service_target, motifs_mapping)
    Rails.logger.info "updating RDV #{rdv.id} with motif #{motif_target.name}..."
    rdv.update!(motif: motif_target) unless simulation
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
