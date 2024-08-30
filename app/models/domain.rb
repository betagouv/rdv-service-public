# Toutes les spécificités des différents domaines doivent apparaître dans ce fichier

Domain = Struct.new(
  :id,
  :name,
  :logo_path,
  :public_logo_path,
  :dark_logo_path,
  :presentation_for_agents_template_name,
  :address_selection_template_name,
  :search_banner_template_name,
  :sms_sender_name,
  :online_reservation_with_public_link,
  :can_sync_to_outlook,
  :france_connect_enabled,
  :agent_connect_allowed,
  :support_email,
  :secretariat_email,
  :verticale,
  keyword_init: true
)

class Domain
  ALL = [
    RDV_SOLIDARITES = new(
      id: "RDV_SOLIDARITES",
      logo_path: "logos/logo_solidarites.svg",
      public_logo_path: "/logo_solidarites.png",
      dark_logo_path: "logos/logo_sombre_solidarites.svg",
      name: "RDV Solidarités",
      presentation_for_agents_template_name: "rdv_solidarites_presentation_for_agents",
      address_selection_template_name: "search/address_selection/rdv_solidarites",
      search_banner_template_name: "search/banners/rdv_solidarites",
      online_reservation_with_public_link: false,
      can_sync_to_outlook: false,
      sms_sender_name: "RdvSoli",
      france_connect_enabled: true,
      agent_connect_allowed: true,
      support_email: "support@rdv-solidarites.fr",
      verticale: :rdv_solidarites,
      secretariat_email: "secretariat-auto@rdv-solidarites.fr"
      # secretariat_email est utilisé comme adresse de "Reply-To" pour les e-mails
      # qui contiennent des ICS. Lorsque l'événement ICS est acceptée par le
      # client mail / calendrier, ce client mail envoie un accusé de réception
      # à cette adresse (ex: "Accepted: RDV Consultation médicale ").
    ),

    RDV_AIDE_NUMERIQUE = new(
      id: "RDV_AIDE_NUMERIQUE",
      logo_path: "logos/logo_aide_numerique.svg",
      public_logo_path: "/logo_aide_numerique.png",
      dark_logo_path: "logos/logo_sombre_aide_numerique.svg",
      name: "RDV Aide Numérique",
      presentation_for_agents_template_name: "presentation_for_cnfs",
      address_selection_template_name: "search/address_selection/rdv_aide_numerique",
      search_banner_template_name: "search/banners/rdv_aide_numerique",
      online_reservation_with_public_link: true,
      can_sync_to_outlook: false,
      sms_sender_name: "RdvAideNum",
      france_connect_enabled: false,
      agent_connect_allowed: false,
      support_email: "support@rdv-aide-numerique.fr",
      verticale: :rdv_aide_numerique,
      secretariat_email: "secretariat-auto@rdv-solidarites.fr"
    ),

    RDV_MAIRIE = new(
      id: "RDV_MAIRIE",
      logo_path: "logos/logo_rdv_service_public.svg",
      public_logo_path: "/logo_rdv_service_public.png",
      dark_logo_path: "logos/logo_sombre_rdv_service_public.svg",
      name: "RDV Service Public",
      presentation_for_agents_template_name: "presentation_for_mairie",
      address_selection_template_name: "search/address_selection/rdv_mairie",
      search_banner_template_name: "search/banners/rdv_mairie",
      online_reservation_with_public_link: true,
      can_sync_to_outlook: false,
      sms_sender_name: "RDV S.P.",
      france_connect_enabled: true,
      agent_connect_allowed: true,
      support_email: "support@rdv-service-public.fr",
      verticale: :rdv_mairie,
      secretariat_email: "secretariat-auto@rdv-service-public.fr"
    ),
  ].freeze

  def documentation_url
    "https://rdvs.notion.site/Centre-d-aide-f0a2bf87ca854fbc8855a2a20d6eb4d1"
  end

  def host_name
    case Rails.env.to_sym
    when :production
      if ENV["IS_REVIEW_APP"] == "true"
        # Les review apps utilisent un domaine de Scalingo, elles
        # ne permettent donc pas d'utiliser plusieurs domaines.
        URI.parse(ENV.fetch("HOST", nil)).host
      elsif ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
        {
          RDV_SOLIDARITES => "demo.rdv-solidarites.fr",
          RDV_AIDE_NUMERIQUE => "demo.rdv-aide-numerique.fr",
          RDV_MAIRIE => "demo.rdv.anct.gouv.fr",
        }.fetch(self)
      else
        {
          RDV_SOLIDARITES => "www.rdv-solidarites.fr",
          RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique.fr",
          RDV_MAIRIE => "rdv.anct.gouv.fr",
        }.fetch(self)
      end
    when :development
      {
        RDV_SOLIDARITES => "www.rdv-solidarites.localhost",
        RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique.localhost",
        RDV_MAIRIE => "www.rdv-mairie.localhost",
      }.fetch(self)
    when :test
      {
        RDV_SOLIDARITES => "www.rdv-solidarites-test.localhost",
        RDV_AIDE_NUMERIQUE => "www.rdv-aide-numerique-test.localhost",
        RDV_MAIRIE => "www.rdv-mairie-test.localhost",
      }.fetch(self)
    else
      raise "Rails.env not recognized: #{Rails.env.inspect}"
    end
  end

  def default?
    self == RDV_MAIRIE
  end
  alias default default?

  ALL_BY_HOST_NAME = ALL.index_by(&:host_name)

  def self.find_matching(domain_name)
    return review_app_domain if ENV["IS_REVIEW_APP"] == "true"

    ALL_BY_HOST_NAME.fetch(domain_name) { RDV_SOLIDARITES }
  end

  # Les review apps utilisent un host de Scalingo, elles ne permettent
  # donc pas de tester la correspondance du domaine via le host.
  def self.review_app_domain
    if ENV["REVIEW_APP_DOMAIN"].present?
      find(ENV["REVIEW_APP_DOMAIN"])
    else
      RDV_SOLIDARITES
    end
  end

  def self.find(id)
    ALL.find { _1.id == id } or raise "Can't find domain with id=#{id}"
  end

  def to_s
    name
  end
end
