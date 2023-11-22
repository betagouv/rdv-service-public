# scalingo --app=production-rdv-solidarites --region=osc-secnum-fr1 run --file=tmp/agents_de_la_drome.csv --file=tmp/noms_motifs_drome.csv bundle exec rails console

require "csv"

class MotifMigrator
  def initialize(motif, new_name, new_service)
    @motif = motif
    @new_name = new_name
    @new_service = new_service
  end

  def migrate!
    return unless changing_name? || changing_service?

    puts_log

    if existing_motif.present?
      merge_motif_into_existing_one
    else
      @motif.update!(name: definitive_name, service: definitive_service)
    end
  end

  private

  def definitive_name
    @new_name.presence || @motif.name
  end

  def definitive_service
    @new_service.presence || @motif.service
  end

  # rubocop:disable Rails/SkipsModelValidations
  def merge_motif_into_existing_one
    @motif.rdvs.update_all(motif_id: existing_motif.id)
    @motif.motifs_plage_ouvertures.update_all(motif_id: existing_motif.id)
    @motif.skip_webhooks = true
    @motif.destroy!
  end
  # rubocop:enable Rails/SkipsModelValidations

  def existing_motif
    @motif.organisation.motifs.active.find_by(name: definitive_name, service: definitive_service, location_type: @motif.location_type)
  end

  def changing_name?
    @new_name.present? && @new_name != @motif.name
  end

  def changing_service?
    @new_service.present? && @new_service != @motif.service
  end

  def puts_log
    puts "-" * 80
    puts "Migration du motif #{@motif.id}: #{@motif.name} (nouveau nom: #{@new_name}, nouveau service: #{@new_service&.name})"
    puts "-" * 80
  end
end

def migrate_motifs(territory)
  motifs_de_la_drome = Motif.active.where(organisation: Organisation.where(territory: territory))

  CSV.foreach("/tmp/uploads/noms_motifs_drome.csv", headers: true, col_sep: ",", liberal_parsing: true) do |row|
    initial_name = row["Motif"]
    initial_service = Service.find_by!(name: row["Service"])
    new_name = row["Nom définitif du motif"]
    new_service = Service.find_by!(name: row["Service de destination"]) if row["Service de destination"].present?

    motifs_de_la_drome.where(name: initial_name, service: initial_service).find_each do |motif|
      MotifMigrator.new(motif, new_name, new_service).migrate!
    end
  end
end

def migrate_agents(territory)
  pmi_css = Service.find_by!(name: "PMI - Centre Santé Sexuelle")
  pmi = Service.find_by!(short_name: "PMI")
  css = Service.find_by!(short_name: "CSS")

  CSV.foreach("/tmp/uploads/agents_de_la_drome.csv", headers: true, col_sep: ",", liberal_parsing: true) do |row|
    agent = Agent.find_by!(email: row["email"])
    next unless agent.services == [pmi_css]
    raise "woops" if row["service"] != "PMI - Centre Santé Sexuelle"

    new_services = case row["new_service"]
                   when "CSS + PMI"
                     [pmi, css]
                   when "CSS"
                     [css]
                   else
                     [pmi]
                   end

    agent.services = new_services
  end

  territory.services << pmi
  territory.services << css
  territory.services.delete(pmi_css)
end

Motif.transaction do
  drome = Territory.find(4)
  migrate_motifs(drome)
  migrate_agents(drome)
end
