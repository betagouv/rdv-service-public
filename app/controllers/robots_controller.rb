class RobotsController < ApplicationController
  layout false

  respond_to :text

  def robots
    @domain_is_public = current_domain.in?([Domain::RDV_SOLIDARITES, Domain::RDV_AIDE_NUMERIQUE, Domain::RDV_MAIRIE])
  end
end
