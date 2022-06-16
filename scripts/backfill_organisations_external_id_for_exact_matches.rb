# frozen_string_literal: true

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  agent = Agent.find_by(external_id: conseiller_numerique["Email @conseiller-numerique.fr"])

  next if Organisation.find_by(external_id: conseiller_numerique["Id de la structure"])
  next unless agent

  exact_match = agent.organisations.count == 1 && agent.organisations.first.agents == [agent]

  if exact_match
    organisation = agent.organisations.first
    # rubocop:disable Rails/SkipsModelValidations
    organisation.update_columns(external_id: conseiller_numerique["Id de la structure"])
    # rubocop:enable Rails/SkipsModelValidations
    puts "Backfill effectué pour #{conseiller_numerique['Nom de la structure']} (#{conseiller_numerique['Id de la structure']})"
  else
    puts "Il y a plusieurs agents dans l'organisation #{conseiller_numerique['Nom de la structure']}. Ce cas sera traité dans un autre script."
  end
end
