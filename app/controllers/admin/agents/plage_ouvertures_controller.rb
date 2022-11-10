# frozen_string_literal: true

class Admin::Agents::PlageOuverturesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    @agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @plage_ouverture_occurrences = plage_ouvertures.all_occurrences_for(date_range_params)
  end

  private

  def plage_ouvertures
    plage = custom_policy.includes(:lieu, :organisation).where(agent: @agent)
    plage = plage.where(id: params[:plages_ids]) if params[:plages_ids].present?
    plage
  end

  # TODO: custom policy waiting for policies refactoring
  def custom_policy
    context = AgentOrganisationContext.new(current_agent, @organisation)
    Agent::PlageOuverturePolicy::DepartementScope.new(context, PlageOuverture)
      .resolve
  end

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end
  helper_method :date_range_params

  def pundit_user
    AgentContext.new(current_agent)
  end
end
