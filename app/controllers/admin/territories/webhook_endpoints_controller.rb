class Admin::Territories::WebhookEndpointsController < Admin::Territories::BaseController
  before_action :set_webhook_endpoint, only: %i[edit update destroy]

  def index
    @webhooks = policy_scope(WebhookEndpoint).where(organisation: current_territory.organisations)
  end

  def new
    @webhook = WebhookEndpoint.new
    authorize_with_legacy_configuration_scope current_territory, :edit?
  end

  def create
    @webhook = WebhookEndpoint.new(webhook_endpoint_params)
    authorize_with_legacy_configuration_scope @webhook
    if @webhook.save
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def edit
    authorize_with_legacy_configuration_scope @webhook
  end

  def update
    authorize_with_legacy_configuration_scope @webhook

    params = webhook_endpoint_params[:secret] == @webhook.partially_hidden_secret ? webhook_endpoint_params.except(:secret) : webhook_endpoint_params

    if @webhook.update(params)
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    authorize_with_legacy_configuration_scope @webhook
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
