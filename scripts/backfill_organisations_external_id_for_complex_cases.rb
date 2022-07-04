# frozen_string_literal: true

cnfs_territory_id = 31
experimental_organisation_id = 340

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

def find_cnfs_by(email, conseillers_numeriques)
  conseillers_numeriques.find do |conseiller|
    conseiller["Email @conseiller-numerique.fr"] == email
  end
end

Territory.find(cnfs_territory_id).organisations.where(external_id: nil).where.not(id: experimental_organisation_id).find_each do |organisation|
  puts "Processing #{organisation.name}"

  most_active_agent_id = organisation.rdvs.joins(agents_rdvs: :agent).where.not(agents: { external_id: nil }).group(:agent_id).count.max_by { |_k, v|; v }&.first

  most_active_agent = Agent.where.not(external_id: nil).find_by(id: most_active_agent_id)

  most_active_agent ||= organisation.agents.where.not(external_id: nil).first

  cnfs = nil

  if most_active_agent
    cnfs = find_cnfs_by(most_active_agent.external_id, conseillers_numeriques)
  else
    possible_cnfs_emails = organisation.agents.pluck(:external_id)
    cnfs = possible_cnfs_emails.find do |email|
      find_cnfs_by(email, conseillers_numeriques)
    end
  end

  next unless cnfs

  organisation.update(external_id: cnfs["Id de la structure"])
end
