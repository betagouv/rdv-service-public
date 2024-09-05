require "csv"

module Departements
  CSV_PATH = Rails.root.join("lib/assets/departements_fr.csv").freeze
  NAMES = CSV.read(CSV_PATH, headers: :first_row)
    .to_h { [_1["number"], _1["name"]] }
end
