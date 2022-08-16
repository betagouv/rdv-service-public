# frozen_string_literal: true

class Domain < OpenStruct
  ALL = [
    RDV_SOLIDARITES = new(
      default: true,
      logo_path: "logos/logo.svg",
      public_logo_path: "/logo.png",
      dark_logo_path: "logos/logo_sombre.svg",
      name: "RDV Solidarités",
      sms_sender_name: "RdvSoli",
      slug: "rdv_solidarites"
    ),

    RDV_INCLUSION_NUMERIQUE = new(
      logo_path: "logos/logo-cnfs.svg", # TODO: make a new logo
      public_logo_path: "/logo-cnfs.svg", # TODO: make a new logo
      dark_logo_path: "logos/logo-cnfs_sombre.svg", # TODO: make a new logo
      name: "RDV Inclusion Numérique",
      sms_sender_name: "Rdv Num",
      slug: "rdv_inclusion_numerique"
    ),
  ].freeze

  def dns_domain_name
    case Rails.env.to_sym
    when :production
      if ENV["RDV_SOLIDARITES_IS_REVIEW_APP"] == "true"
        # use review app's host for both RDV Solidarité and RDV Inclusion Numérique
        URI.parse(ENV["HOST"]).host
      elsif ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
        {
          RDV_SOLIDARITES => "demo.rdv-solidarites.fr",
          RDV_INCLUSION_NUMERIQUE => "demo.rdv-inclusion-numerique.fr",
        }.fetch(self)
      else
        {
          RDV_SOLIDARITES => "rdv-solidarites.fr",
          RDV_INCLUSION_NUMERIQUE => "rdv-inclusion-numerique.fr",
        }.fetch(self)
      end
    when :development
      {
        RDV_SOLIDARITES => "rdv-solidarites.localhost",
        RDV_INCLUSION_NUMERIQUE => "rdv-inclusion-numerique.localhost",
      }.fetch(self)
    when :test
      {
        RDV_SOLIDARITES => "rdv-solidarites-test.localhost",
        RDV_INCLUSION_NUMERIQUE => "rdv-inclusion-numerique-test.localhost",
      }.fetch(self)
    else
      raise "Rails.env not recognized: #{Rails.env.inspect}"
    end
  end

  def self.find_matching(domain_name)
    ALL.find do |domain|
      domain_name[domain.dns_domain_name].present?
    end || RDV_SOLIDARITES
  end
end
