# frozen_string_literal: true

class Admin::Territories::WebhookEndpointsController < Admin::Territories::BaseController
  before_action :set_webhook_endpoint, only: %i[edit update destroy]

  def index
    @webhooks = policy_scope(WebhookEndpoint).where(organisation: current_territory.organisations)
  end

  def new
    @webhook = WebhookEndpoint.new
    authorize @webhook
  end

  def create
    @webhook = WebhookEndpoint.new(webhook_endpoint_params)
    authorize @webhook
    if @webhook.save
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def edit
    authorize @webhook
  end

  def update
    authorize @webhook
    if @webhook.update(webhook_endpoint_params)
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    authorize @webhook
    @webhook.destroy
    redirect_to admin_territory_webhook_endpoints_path(current_territory)
  end

  private

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(
      :target_url, :secret, :organisation_id, subscriptions: []
    )
  end

  def set_webhook_endpoint
    @webhook = WebhookEndpoint.find(params[:id])
  end
end
