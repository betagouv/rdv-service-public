class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  layout false

  respond_to :text

  def robots
    @domain_is_public = ENV["RDV_SOLIDARITES_INSTANCE_NAME"] != "DEMO"
  end
end
