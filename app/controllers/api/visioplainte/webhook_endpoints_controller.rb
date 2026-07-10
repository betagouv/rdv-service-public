# cf docs/interconnexions/visioplainte.md

class Api::Visioplainte::WebhookEndpointsController < Api::Visioplainte::BaseController
  def index
    webhook_endpoints = authorized_webhook_endpoint_scope.order(:id)
    render json: WebhookEndpointBlueprint.render(webhook_endpoints, root: :webhook_endpoints)
  end

  def create
    @webhook_endpoint = WebhookEndpoint.new(permitted_params)
    @webhook_endpoint.organisation_id = Territory.visioplainte.first.organisations.sole.id
    @webhook_endpoint.save!
    render json: WebhookEndpointBlueprint.render(@webhook_endpoint), status: :created
  end

  def update
    @webhook_endpoint = authorized_webhook_endpoint_scope.find(params[:id])
    @webhook_endpoint.update!(permitted_params)
    render_record @webhook_endpoint
  end

  def destroy
    @webhook_endpoint = authorized_webhook_endpoint_scope.find(params[:id])
    @webhook_endpoint.delete!

    head :no_content
  end

  private

  def authorized_webhook_endpoint_scope
    WebhookEndpoint.joins(organisation: :territory).merge(Territory.visioplainte)
  end

  def permitted_params
    params.permit(:target_url, :secret, subscriptions: [])
  end
end
