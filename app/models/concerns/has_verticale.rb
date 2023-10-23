# frozen_string_literal: true

module HasVerticale
  extend ActiveSupport::Concern

  included do
    enum verticale: {
      rdv_insertion: "rdv_insertion",
      rdv_solidarites: "rdv_solidarites",
      rdv_aide_numerique: "rdv_aide_numerique",
      rdv_mairie: "rdv_mairie",
    }
  end
end
