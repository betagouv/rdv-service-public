# frozen_string_literal: true

module DomainConcern
  extend ActiveSupport::Concern

  private

  def domain
    if @agent
      @agent.service.domain
    elsif @rdv
      @rdv.motif.service.domain
    elsif @absence
      @absence.agent.service.domain
    elsif @plage_ouverture
      @plage_ouverture.agent.service.domain
    else
      Domain::RDV_SOLIDARITES
    end
  end

  def default_url_options
    super.merge(host: domain.dns_domain_name)
  end
end
