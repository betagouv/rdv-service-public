# frozen_string_literal: true

module Motif::Category
  extend ActiveSupport::Concern

  included do
    enum category: {
      rsa_orientation: "rsa_orientation",
      rsa_accompagnement: "rsa_accompagnement",
      rsa_accompagnement_social: "rsa_accompagnement_social",
      rsa_accompagnement_sociopro: "rsa_accompagnement_sociopro",
      rsa_orientation_on_phone_platform: "rsa_orientation_on_phone_platform",
      rsa_cer_signature: "rsa_cer_signature",
      rsa_insertion_offer: "rsa_insertion_offer",
      rsa_follow_up: "rsa_follow_up",
      rsa_main_tendue: "rsa_main_tendue",
      rsa_atelier_collectif_mandatory: "rsa_atelier_collectif_mandatory",
      rsa_spie: "rsa_spie",
    }
  end
end
