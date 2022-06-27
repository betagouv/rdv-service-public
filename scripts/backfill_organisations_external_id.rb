# frozen_string_literal: true

# Usage :
# scalingo run "rails runner scripts/backfill_organisations_external_id.rb" --app production-rdv-solidarites --region osc-secnum-fr1 --file tmp/export-cnfs.csv
# A one-off script to backfill organisations.external_ids
# This script can be deleted after we run it once

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  structure_name = conseiller_numerique["Nom de la structure"]
  structure_id = conseiller_numerique["Id de la structure"]

  next if Organisation.find_by(external_id: structure_id)

  version = PaperTrail::Version.where(item_type: "Organisation", event: "create")
    .where("object_changes ilike ?", "%name:_- _- #{structure_name}%").first
  # The '_' character matches any character when using ilike.
  # It's easier to use this expression rather than parsing yaml for each version

  organisation = version&.item
  next unless organisation || organisation&.external_id
  next if organisation.territory_id != 31 # This is the territory_id for the CNFS territory

  # Only set the external_id if it really matches the current agent
  if organisation.agents.find_by(external_id: conseiller_numerique["Email @conseiller-numerique.fr"])
    organisation.update!(external_id: structure_id)
    puts "Backfill done for #{structure_name}"
  end
end
