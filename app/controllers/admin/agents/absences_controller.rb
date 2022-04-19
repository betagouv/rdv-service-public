# frozen_string_literal: true

class Admin::Agents::AbsencesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    absences = policy_scope_admin(Absence).includes(:organisation).where(agent: agent)
    # Cache occurrences for this relation
    @absence_occurrences = cache([absences, :all_occurrences_for, date_range_params]) do
      absences.all_occurrences_for(date_range_params)
    end
  end

  private

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
