# frozen_string_literal: true

class Admin::Territories::WebhookEndpointsController < Admin::Territories::BaseController
  def index
    @webhooks = policy_scope_admin(WebhookEndpoint).where(organisation: current_territory.organisations)
  end

  def new
    @webhook = WebhookEndpoint.new
    skip_authorization
  end

  def create
    @webhook = WebhookEndpoint.new(webhook_endpoint_params)
    authorize_admin(@webhook)
    if @webhook.save
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def edit
    @webhook = WebhookEndpoint.find(params[:id])
    authorize_admin(@webhook)
  end

  def update
    @webhook = WebhookEndpoint.find(params[:id])
    authorize_admin(@webhook)
    if @webhook.update(webhook_endpoint_params)
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    policy_scope_admin(WebhookEndpoint).find(params[:id]).destroy
    redirect_to admin_territory_webhook_endpoints_path(current_territory)
  end

  private

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(
      :target_url, :secret, :organisation_id, triggering_resources: []
    )
  end
end
