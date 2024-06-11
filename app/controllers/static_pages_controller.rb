class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
    render layout: "application_base"
  end

  def accessibility; end

  def contact; end

  def domaines; end

  def health_check
    Territory.count # check connection to DB is working
  end

  def presentation_for_agents
    render current_domain.presentation_for_agents_template_name
  end

  def microsoft_domain_verification
    # see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain#select-a-verified-domain
    response.headers["Content-Type"] = "application/json"

    render # pour avoir un response.body sur lequel calculer Content-Length

    response.headers["Content-Length"] = response.body.length.to_s
  end
end
