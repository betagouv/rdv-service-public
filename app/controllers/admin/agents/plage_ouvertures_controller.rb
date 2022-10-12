# frozen_string_literal: true

class Admin::Agents::PlageOuverturesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    @agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    # Cache occurrences for this relation
    @plage_ouverture_occurrences = cache([plage_ouvertures, :all_occurrences_for, date_range_params]) do
      plage_ouvertures.all_occurrences_for(date_range_params)
    end
  end

  private

  def plage_ouvertures
    if params[:plages_ids].present?
      PlageOuverture.where(id: params[:plages_ids])
    else
      custom_policy.includes(:lieu, :organisation).where(agent: @agent)
    end
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

  def pundit_user
    AgentContext.new(current_agent)
  end
end
