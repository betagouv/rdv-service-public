# frozen_string_literal: true

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
  :faq_url,
  :documentation_url,
  :support_email,
  :secretariat_email,
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
      documentation_url: "https://rdvs.notion.site/RDV-Solidarit-s-94176a1507814d19aeaaf6e678ffcbed",
      faq_url: "https://rdv-solidarites.notion.site/F-A-Q-M-dico-social-aaf94709c0ea448b8eb9d93f548acdb9",
      france_connect_enabled: true,
      support_email: "support@rdv-solidarites.fr",
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
      documentation_url: "https://rdvs.notion.site/RDV-Aide-Num-rique-cd6f04a9d90a444a800d81f77428eaf4",
      faq_url: "https://rdvs.notion.site/FAQ-CNFS-c55933f66f054aaba60fe4799851000e",
      france_connect_enabled: false,
      support_email: "support@rdv-aide-numerique.fr",
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
      documentation_url: "https://rdvs.notion.site/RDV-Mairie-b831caa05dd7416bb489f06f7468903a",
      faq_url: "https://rdvs.notion.site/FAQ-RDV-Mairie-6baf4af187a14e42beafe56b7005d199",
      france_connect_enabled: true,
      support_email: "support@rdv-service-public.fr",
      secretariat_email: "secretariat-auto@rdv-service-public.fr"
    ),
  ].freeze

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
          RDV_MAIRIE => "demo.rdv-mairie.fr",
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
