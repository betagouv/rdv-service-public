class StaticPagesController < ApplicationController
  before_action -> { @site_vitrine_page = true }
  def mds
    if current_domain == Domain::RDV_SOLIDARITES
      render layout: "application_base"
    else
      redirect_to root_path
    end
  end

  def accessibilite; end

  def presentation_for_agents
    render current_domain.presentation_for_agents_template_name, layout: "application_base"
  end

  def microsoft_domain_verification
    # see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain#select-a-verified-domain
    response.headers["Content-Type"] = "application/json"

    render # pour avoir un response.body sur lequel calculer Content-Length

    response.headers["Content-Length"] = response.body.length.to_s
  end

  def france_connect_sector_identifier
    response.headers["Content-Type"] = "application/json"

    redirect_urls = Domain::ALL.map(&:host_name).map do |host_name|
      franceconnect_v2_callback_url(host: host_name)
    end

    if ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
      # Le nom de domaine demo.rdv.anct.gouv.fr n'a pas encore été migré pour pointer vers le nouveau serveur de démo
      # pour ne pas bloquer les agents qui s'en servent pour des tests ou des formations.
      # On pourra supprimer cette ligne quand ça sera fait.
      redirect_urls << franceconnect_v2_callback_url(host: "demo-rdv-service-public.osc-secnum-fr1.scalingo.io")
    end
    render json: redirect_urls
  end
end
