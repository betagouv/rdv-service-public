# cf docs/interconnexions/visioplainte.md

class Api::Visioplainte::WebhookEndpointsController < Api::Visioplainte::BaseController
  def index
    render_collection(authorized_webhook_endpoint_scope.order(:id))
  end

  def create
    @webhook_endpoint = WebhookEndpoint.new(permitted_params)
    authorize(@webhook_endpoint, policy_class: Agent::WebhookEndpointPolicy)
    @webhook_endpoint.save!
    render_record @webhook_endpoint
  end

  def update
    @webhook_endpoint = authorized_webhook_endpoint_scope.find(params[:id])
    @webhook_endpoint.update!(permitted_params)
    render_record @webhook_endpoint
  end

  def delete; end

  private

  def set_webhook_endpoint
    @webhook_endpoint = policy_scope(WebhookEndpoint, policy_scope_class: Agent::WebhookEndpointPolicy::Scope).find(params[:id])
    authorize(@webhook_endpoint, policy_class: Agent::WebhookEndpointPolicy)
  end

  def authorized_webhook_endpoint_scope
    WebhookEndpoint.joins(organisation: :territory).merge(Territory.visioplainte)
  end

  def permitted_params
    params.permit(:target_url, :secret, subscriptions: [])
  end
end
