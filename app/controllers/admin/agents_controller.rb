# frozen_string_literal: true

class Admin::AgentsController < AgentAuthController
  respond_to :json

  def index
    @agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .includes(:service, :roles, :organisations)
      .active.complete
    @agents = index_params[:term].present? ? @agents.search_by_text(index_params[:term]) : @agents.order_by_last_name
  end

  private

  def index_params
    @index_params ||= params.permit(:term)
  end
end
