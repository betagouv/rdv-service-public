# frozen_string_literal: true

class Admin::Agents::RdvsController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = custom_policy
      .merge(agent.rdvs)
      .includes(%i[organisation lieu motif users rdvs_users])
    @rdvs = @rdvs.where(starts_at: date_range_params) if date_range_params.present?
    @rdvs = @rdvs.where(status: params[:status]) if params[:status].present?
  end

  private

  # TODO: custom policy waiting for policies refactoring
  def custom_policy
    context = AgentOrganisationContext.new(current_agent, @organisation)
    Agent::RdvPolicy::DepartementScope.new(context, Rdv)
      .resolve
  end

  def pundit_user
    AgentContext.new(current_agent)
  end

  def date_range_params
    return unless params[:start].present? && params[:end].present?

    start_param = Time.zone.parse(params[:start])
    end_param = Time.zone.parse(params[:end])
    start_param..end_param
  end
end
