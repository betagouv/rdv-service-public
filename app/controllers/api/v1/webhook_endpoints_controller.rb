# frozen_string_literal: true

class Api::V1::WebhookEndpointsController < Api::V1::AgentAuthBaseController
  before_action :set_webhook_endpoint, only: %i[update]
  before_action :set_organisation, only: %i[index create update]

  def index
    webhook_endpoints = policy_scope(WebhookEndpoint).where(organisation_id: params[:organisation_id])
    webhook_endpoints = webhook_endpoints.where(target_url: params[:target_url]) if params[:target_url].present?
    render_collection(webhook_endpoints)
  end

  def create
    @webhook_endpoint = WebhookEndpoint.new(webhook_endpoint_params)
    authorize @webhook_endpoint
    @webhook_endpoint.save!
    @webhook_endpoint.trigger_for_all_subscribed_resources
    render_record @webhook_endpoint
  end

  def update
    @webhook_endpoint.update!(webhook_endpoint_params)
    @webhook_endpoint.trigger_for_all_subscribed_resources
    render_record @webhook_endpoint
  end

  private

  def set_webhook_endpoint
    @webhook_endpoint = policy_scope(WebhookEndpoint).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :webhook_endpoint unless @webhook_endpoint
    authorize @webhook_endpoint
  end

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :organisation unless @organisation
  end

  def webhook_endpoint_params
    params.permit(:target_url, :secret, :organisation_id, subscriptions: [])
  end
end
