require "csv"

class CreateTerritories < ActiveRecord::Migration[6.0]
  DEPARTEMENT_PHONE_NUMBERS = {
    "08" => "0231571414",
    "22" => "0296608686",
    "55" => "0329803234",
    "64" => "0559693411",
    "77" => "0164147777",
    "80" => "0322718080",
    "92" => "0806000092",
    "95" => "0134253030",
  }.freeze

  def up
    create_table :territories do |t|
      t.string :departement_number
      t.string :name
      t.string :phone_number
      t.string :phone_number_formatted
      t.timestamps
    end

    create_table :agent_territorial_roles do |t|
      t.references :agent
      t.references :territory
    end

    change_table(:organisations) { _1.references :territory }
    Organisation.all.each { attach_organisation!(_1) }
    change_column_null :organisations, :territory_id, false

    change_table(:sectors) { _1.references :territory }
    Sector.all.each { attach_sector!(_1) }
    change_column_null :sectors, :territory_id, false

    create_agent_territorial_roles!
    create_missing_agent_territorial_roles!

    raise if Territory.all.any? { _1.agents.empty? } && ENV["HOST"].exclude?("demo")

    change_column_null :organisations, :departement, true # so we can keep creating orgas
    change_column_null :sectors, :departement, true # so we can keep creating sectors
  end

  def down
    remove_column :sectors, :territory_id
    remove_column :organisations, :territory_id
    drop_table :agent_territorial_roles
    drop_table :territories
  end

  private

  def attach_organisation!(organisation)
    organisation.update_columns(
      territory_id: Territory.find_or_create_by!(
        departement_number: organisation.departement,
        name: Territory::DEPARTEMENTS_NAMES.fetch(organisation.departement, "N/A"),
        phone_number: DEPARTEMENT_PHONE_NUMBERS.fetch(organisation.departement, nil)
      ).id
    )
  end

  def attach_sector!(sector)
    sector.update_columns(
      territory_id: Territory.find_by!(departement_number: sector.departement).id
    )
  end

  def create_agent_territorial_roles!
    return if ENV["MIGRATION_AGENT_TERRITORIAL_ROLES_CSV_URL"].blank?

    CSV.parse(
      Typhoeus.get(ENV["MIGRATION_AGENT_TERRITORIAL_ROLES_CSV_URL"]).body,
      headers: :first_row
    ).each do |csv_row|
      agent = Agent.find_by(email: csv_row["agent_email"])
      if agent.nil?
        Rails.logger.debug { "could not find agent for #{csv_row['agent_email']}" }
        next
      end
      AgentTerritorialRole.create!(
        territory: Territory.find_by!(departement_number: csv_row["departement"]),
        agent: agent
      )
    end
  end

  def create_missing_agent_territorial_roles!
    return if Rails.env.production? && ENV["HOST"].exclude?("demo")

    Territory.all.to_a.select { _1.agents.empty? }.each do |territory|
      Agent
        .where(
          id: AgentRole
            .joins(:organisation)
            .where(organisations: { territory_id: territory.id }, level: :admin)
            .select(:agent_id)
        )
        .each { AgentTerritorialRole.create!(territory: territory, agent: _1) }
    end
  end
end
