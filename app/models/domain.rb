# frozen_string_literal: true

class Domain
  attr_reader :dns_domain_name, :default

  def initialize(dns_domain_name:, default: false)
    @default = default
    @dns_domain_name = dns_domain_name
  end

  ALL = [
    RDV_SOLIDARITES = new(
      default: true,
      dns_domain_name: "rdv-solidarites.fr",
      logo_path: "/logo.png",
      name: "RDV Solidarités"
    ),

    RDV_CNFS = new(
      dns_domain_name: "rdv-conseiller-numerique.fr",
      logo_path: "/logo-conseiller-numerique.svg",
      name: "RDV Conseiller Numérique"
    ),
  ].freeze
end
