# rails runner scripts/export_cnfs_agents.rb

require "csv"

class ExportCnfsAgents
  def call
    commands = %w[
      top_agents_by_rdvs_count
      agents_with_rdvs_created_by_user_or_prescripteur
      agents_who_activated_their_count_recently
      agents_with_creneaux_in_multiple_locations
      agents_with_rdvs_collectif
    ]

    export_files = commands.map do |command|
      to_csv(send(command), filename: "#{command}.csv")
    end

    puts "Exports files are located at", export_files
  end

  private

  def top_agents_by_rdvs_count(limit: 100)
    agents.joins(:agents_rdvs).select(
      "agents.id",
      "agents.email",
      "agents.first_name",
      "agents.last_name",
      "COUNT(agent_id) NOMBRE_DE_RDVS"
    ).group("agents.id").order("NOMBRE_DE_RDVS desc").limit(limit)
  end

  def agents_with_rdvs_created_by_user_or_prescripteur
    agents.joins(agents_rdvs: :rdv).select(
      "agents.id",
      "agents.email",
      "agents.first_name",
      "agents.last_name"
    ).where(rdvs: { created_by_type: %w[User Prescripteur] })
  end

  def agents_who_activated_their_count_recently(interval: 30.days.ago)
    agents.where("invitation_accepted_at > ?", interval).select(
      "agents.id",
      "agents.email",
      "agents.first_name",
      "agents.last_name",
      "DATE(agents.invitation_accepted_at) DATE_DE_CONFIRMATION"
    )
  end

  def agents_with_creneaux_in_multiple_locations
    agents.joins(:plage_ouvertures).select(
      "agents.id",
      "agents.email",
      "agents.first_name",
      "agents.last_name",
      "COUNT(lieu_id) lieux_count"
    ).group("agents.id").having("COUNT(lieu_id)> 1")
  end

  def agents_with_rdvs_collectif
    agents.joins(agents_rdvs: [{ rdv: :motif }]).select(
      "agents.id",
      "agents.email",
      "agents.first_name",
      "agents.last_name"
    ).distinct.where(motifs: { collectif: true })
  end

  def to_csv(records, filename: "doc.csv")
    return if records.first.nil?

    CSV.open(Rails.root.join("tmp", filename).to_s, "wb") do |csv|
      attributes = records.first.attributes.keys
      csv << attributes
      records.each do |record|
        csv << record.attributes.values
      end

      csv.path
    end
  end

  def agents
    @agents ||= Agent.in_any_of_these_services([Service.find_by_name(Service::CONSEILLER_NUMERIQUE)])
  end
end

ExportCnfsAgents.new.call
