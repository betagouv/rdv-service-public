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
    TriggerWebhookJob.perform_later(@webhook_endpoint.id) unless trigger_disabled
    render_record @webhook_endpoint
  end

  def update
    @webhook_endpoint.update!(webhook_endpoint_params)
    TriggerWebhookJob.perform_later(@webhook_endpoint.id) unless trigger_disabled
    render_record @webhook_endpoint
  end

  private

  def trigger_disabled
    params[:trigger].present? && params[:trigger] == false
  end

  def set_webhook_endpoint
    @webhook_endpoint = policy_scope(WebhookEndpoint).find(params[:id])
    authorize @webhook_endpoint
  end

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def permitted_params
    params.permit(:target_url, :secret, :organisation_id, :trigger, subscriptions: [])
  end

  def webhook_endpoint_params
    permitted_params.except(:trigger)
  end
end
