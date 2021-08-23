# frozen_string_literal: true

class Admin::Territories::WebhookConfigurationsController < Admin::Territories::BaseController

  def index
    @webhooks = WebhookEndpoint.where(organisation: current_territory.organisations)
  end

end
