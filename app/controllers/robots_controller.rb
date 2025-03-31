class RobotsController < ApplicationController
  layout false

  respond_to :text

  def robots
    @domain_is_public = domain_is_public?
  end

  private

  def domain_is_public?
    return false if ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
    return false if URI.parse(request.url).host&.ends_with?("rdv.numerique.gouv.fr")

    true
  end
end
