# frozen_string_literal: true

class Api::V1::WebhookEndpointsController < Api::V1::AgentAuthBaseController
  before_action :set_organisation, only: %i[create update]

  def create
    @webhook_endpoint = WebhookEndpoint.create!(webhook_endpoint_params)
    render_record @webhook_endpoint
  end

  def update
    @webhook_endpoint = WebhookEndpoint.find_by(
      organisation_id: webhook_endpoint_params[:organisation_id],
      target_url: webhook_endpoint_params[:target_url]
    )
    @webhook_endpoint.update!(webhook_endpoint_params)
    render_record @webhook_endpoint
  end

  private

  def set_organisation
    @organisation = Organisation.find(webhook_endpoint_params[:organisation_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :organisation unless @organisation
    authorize @organisation, :admin_in_record_organisation?
  end

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(:target_url, :secret, :organisation_id, subscriptions: [])
  end
end
