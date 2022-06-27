# frozen_string_literal: true

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  AddConseillerNumerique.process!({
    external_id: conseiller_numerique["Email @conseiller-numerique.fr"],
    email: conseiller_numerique["Email @conseiller-numerique.fr"],
    first_name: conseiller_numerique["Prénom"],
    last_name: conseiller_numerique["Nom"],
    structure: {
      external_id: conseiller_numerique["Id de la structure"],
      name: conseiller_numerique["Nom de la structure"],
      address: conseiller_numerique["Adresse de la structure"],
    },
  }.with_indifferent_access)

  puts "Import ou mise à jour réussie pour #{conseiller_numerique['Email @conseiller-numerique.fr']}"
end
