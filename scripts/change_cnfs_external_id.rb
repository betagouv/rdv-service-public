# frozen_string_literal: true

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |cnfs|
  next if cnfs["Email @conseiller-numerique.fr"].blank?

  agent = Agent.find_by(external_id: cnfs["Email @conseiller-numerique.fr"])
  agent&.update!(external_id: "conseiller-numerique-#{cnfs['Id du conseiller']}")
end
