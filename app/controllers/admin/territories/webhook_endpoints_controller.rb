class Admin::Territories::WebhookEndpointsController < Admin::Territories::BaseController
  before_action :set_webhook_endpoint, only: %i[edit update destroy]

  def index
    @webhooks = policy_scope(WebhookEndpoint.where(territory: current_territory), policy_scope_class: Agent::WebhookEndpointPolicy::Scope)
  end

  def new
    @webhook = WebhookEndpoint.new(territory: current_territory, subscriptions: %w[rdv absence plage_ouverture])
    authorize(@webhook, policy_class: Agent::WebhookEndpointPolicy)
  end

  def create
    @webhook = WebhookEndpoint.new(webhook_endpoint_params.merge(territory: current_territory))
    authorize(@webhook, policy_class: Agent::WebhookEndpointPolicy)
    if @webhook.save
      flash[:success] = "Webhook créé"
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :new
    end
  end

  def edit; end

  def update
    params = webhook_endpoint_params[:secret] == @webhook.partially_hidden_secret ? webhook_endpoint_params.except(:secret) : webhook_endpoint_params

    if @webhook.update(params)
      flash[:success] = "Webhook modifié"
      redirect_to admin_territory_webhook_endpoints_path(current_territory)
    else
      render :edit
    end
  end

  def destroy
    @webhook.destroy
    redirect_to admin_territory_webhook_endpoints_path(current_territory)
  end

  private

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(
      :target_url, :secret, subscriptions: [], organisation_ids: []
    )
  end

  def set_webhook_endpoint
    @webhook = WebhookEndpoint.find(params[:id])
    authorize(@webhook, policy_class: Agent::WebhookEndpointPolicy)
  end
end
