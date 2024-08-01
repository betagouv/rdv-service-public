class Admin::Territories::WebhookEndpointsController < Admin::Territories::BaseController
  before_action :set_webhook_endpoint, only: %i[edit update destroy]

  def index
    @webhooks = policy_scope(WebhookEndpoint, policy_scope_class: Agent::WebhookEndpointPolicy::TerritoryScope)
      .where(organisation: current_territory.organisations)
  end

  def new
    @webhook = WebhookEndpoint.new
    authorize_agent @webhook
  end

  def create
    @webhook = WebhookEndpoint.new(webhook_endpoint_params)
    authorize_agent @webhook
    if @webhook.save
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def edit; end

  def update
    params = webhook_endpoint_params[:secret] == @webhook.partially_hidden_secret ? webhook_endpoint_params.except(:secret) : webhook_endpoint_params

    if @webhook.update(params)
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    @webhook.destroy
    redirect_to admin_territory_webhook_endpoints_path(current_territory)
  end

  private

  # On est obligé de redéfinir cette méthode ici tant que le controller parent utilise les AgentTerritorialContext
  def pundit_user
    current_agent
  end

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(
      :target_url, :secret, :organisation_id, subscriptions: []
    )
  end

  def set_webhook_endpoint
    @webhook = WebhookEndpoint.find(params[:id])
    authorize_agent @webhook
  end
end
