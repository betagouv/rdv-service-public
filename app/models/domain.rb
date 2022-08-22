# frozen_string_literal: true

class Domain
  # rubocop:disable Metrics/ParameterLists
  def initialize(logo_path:, public_logo_path:, dark_logo_path:, name:, sms_sender_name:, default: false)
    @logo_path = logo_path
    @public_logo_path = public_logo_path
    @dark_logo_path = dark_logo_path
    @name = name
    @sms_sender_name = sms_sender_name
    @default = default
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :logo_path, :public_logo_path, :dark_logo_path, :name, :sms_sender_name, :default

  ALL = [
    RDV_SOLIDARITES = new(
      default: true,
      logo_path: "logos/logo.svg",
      public_logo_path: "/logo.png",
      dark_logo_path: "logos/logo_sombre.svg",
      name: "RDV Solidarités",
      sms_sender_name: "RdvSoli"
    ),

    RDV_INCLUSION_NUMERIQUE = new(
      logo_path: "logos/logo_inclusion_numerique.svg",
      public_logo_path: "/logo_inclusion_numerique.png",
      dark_logo_path: "logos/logo_sombre_inclusion_numerique.svg",
      name: "RDV Inclusion Numérique",
      sms_sender_name: "Rdv Num"
    ),
  ].freeze

  def dns_domain_name
    case Rails.env.to_sym
    when :production
      if ENV["RDV_SOLIDARITES_IS_REVIEW_APP"] == "true"
        # Les review apps utilisent un domaine de Scalingo, elles
        # ne permettent donc pas d'utiliser plusieurs domaines.
        URI.parse(ENV["HOST"]).host
      elsif ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
        {
          RDV_SOLIDARITES => "demo.rdv-solidarites.fr",
          RDV_INCLUSION_NUMERIQUE => "demo.rdv-inclusion-numerique.fr",
        }.fetch(self)
      else
        {
          RDV_SOLIDARITES => "www.rdv-solidarites.fr",
          RDV_INCLUSION_NUMERIQUE => "www.rdv-inclusion-numerique.fr",
        }.fetch(self)
      end
    when :development
      {
        RDV_SOLIDARITES => "www.rdv-solidarites.localhost",
        RDV_INCLUSION_NUMERIQUE => "www.rdv-inclusion-numerique.localhost",
      }.fetch(self)
    when :test
      {
        RDV_SOLIDARITES => "www.rdv-solidarites-test.localhost",
        RDV_INCLUSION_NUMERIQUE => "www.rdv-inclusion-numerique-test.localhost",
      }.fetch(self)
    else
      raise "Rails.env not recognized: #{Rails.env.inspect}"
    end
  end

  def default?
    !!default
  end

  ALL_BY_URL = ALL.index_by(&:dns_domain_name)

  def self.find_matching(domain_name)
    ALL_BY_URL.fetch(domain_name) { RDV_SOLIDARITES }
  end
end
