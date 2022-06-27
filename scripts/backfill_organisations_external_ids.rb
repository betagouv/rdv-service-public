# frozen_string_literal: true

# A one-off script to backfill organisations.external_ids
# This script can be deleted after we run it once

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  structure_name = conseiller_numerique["Nom de la structure"]
  structure_id = conseiller_numerique["Id de la structure"]

  next if Organisation.find_by(external_id: structure_id)

  version = PaperTrail::Version.where(item_type: "Organisation", event: "create")
    .where("object_changes ilike ?", "%name:_____#{structure_name}%").first
  # The '_' character matches any character when using ilike.
  # It's easier to use this expression rather than parsing yaml for each version

  organisation = version&.item
  organisation.update!(external_id: @structure.external_id)
end
