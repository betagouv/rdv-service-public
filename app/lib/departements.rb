# frozen_string_literal: true

require "csv"

module Departements
  CSV_PATH = Rails.root.join("lib/assets/departements_fr.csv").freeze
  NAMES = CSV.read(CSV_PATH, headers: :first_row)
    .map { [_1["number"], _1["name"]] }
    .to_h
end
