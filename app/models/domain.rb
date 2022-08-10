# frozen_string_literal: true

class Domain < OpenStruct
  ALL = [
    RDV_SOLIDARITES = new(
      default: true,
      dns_domain_name: "rdv-solidarites.fr",
      logo_path: "logos/logo.svg",
      public_logo_path: "/logo.png",
      name: "RDV Solidarités",
      sms_sender_name: "RdvSoli"
    ),

    RDV_CNFS = new(
      dns_domain_name: "rdv-conseiller-numerique.fr",
      logo_path: "logos/logo-cnfs.svg",
      public_logo_path: "/logo-cnfs.svg",
      name: "RDV Conseiller Numérique",
      sms_sender_name: "RdvConseilNum"
    ),
  ].freeze

  def self.find_matching(domain_name)
    ALL.find do |domain|
      domain_name[domain.dns_domain_name].present?
    end || RDV_SOLIDARITES
  end
end
