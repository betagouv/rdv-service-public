# frozen_string_literal: true

class Domain
  # rubocop:disable Metrics/ParameterLists
  def initialize(
    logo_path:,
    public_logo_path:,
    dark_logo_path:,
    name:,
    presentation_for_agents_template_name:,
    sms_sender_name:,
    default: false
  )
    @logo_path = logo_path
    @public_logo_path = public_logo_path
    @dark_logo_path = dark_logo_path
    @name = name
    @presentation_for_agents_template_name = presentation_for_agents_template_name
    @sms_sender_name = sms_sender_name
    @default = default
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :logo_path, :public_logo_path, :dark_logo_path, :name, :presentation_for_agents_template_name, :sms_sender_name, :default

  ALL = [
    RDV_SOLIDARITES = new(
      default: true,
      logo_path: "logos/logo_solidarites.svg",
      public_logo_path: "/logo_solidarites.png",
      dark_logo_path: "logos/logo_sombre_solidarites.svg",
      name: "RDV Solidarités",
      presentation_for_agents_template_name: "rdv_solidarites_presentation_for_agents",
      sms_sender_name: "RdvSoli"
    ),

    RDV_AIDE_NUMERIQUE = new(
      logo_path: "logos/logo_aide_numerique.svg",
      public_logo_path: "/logo_aide_numerique.png",
      dark_logo_path: "logos/logo_sombre_aide_numerique.svg",
      name: "RDV Aide Numérique",
      presentation_for_agents_template_name: "presentation_for_cnfs",
      sms_sender_name: "RdvAideNum"
    ),
  ].freeze

  def dns_domain_name
    case Rails.env.to_sym
    when :production
      if ENV["IS_REVIEW_APP"] == "true"
        # Les review apps utilisent un domaine de Scalingo, elles
        # ne permettent donc pas d'utiliser plusieurs domaines.
        URI.parse(ENV["HOST"]).host
      elsif ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
        {
          RDV_SOLIDARITES => "demo.rdv-solidarites.fr",
          RDV_AIDE_NUMERIQUE => "demo.rdv-aide-numerique.fr",
        }.fetch(self)
      else
        {
          RDV_SOLIDARITES => "www.rdv-solidarites.fr",
          RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique.fr",
        }.fetch(self)
      end
    when :development
      {
        RDV_SOLIDARITES => "www.rdv-solidarites.localhost",
        RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique.localhost",
      }.fetch(self)
    when :test
      {
        RDV_SOLIDARITES => "www.rdv-solidarites-test.localhost",
        RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique-test.localhost",
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
    # Les review apps utilisent un domaine de Scalingo, elles
    # ne permettent donc pas d'utiliser plusieurs domaines.
    return review_app_domain if ENV["IS_REVIEW_APP"] == "true"

    ALL_BY_URL.fetch(domain_name) { RDV_SOLIDARITES }
  end

  def self.review_app_domain
    if ENV["REVIEW_APP_DOMAIN"] == "RDV_AIDE_NUMERIQUE"
      RDV_AIDE_NUMERIQUE
    else
      RDV_SOLIDARITES
    end
  end

  def to_s
    name
  end
end
