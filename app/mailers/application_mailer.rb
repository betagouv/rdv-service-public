# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  prepend IcsMultipartAttached

  default from: SUPPORT_EMAIL
  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper

  private

  helper_method def domain
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
