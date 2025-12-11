class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent"

  before_action :authorize_organisation, if: -> { params[:organisation_id].present? }
  before_action :set_selected_agents_in_agenda
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation, :current_territory, :policy_scope, :from_modal?

  private

  def pundit_user
    @pundit_user ||= AgentOrganisationContext.new(current_agent, current_organisation)
  end
  helper_method :pundit_user

  def set_organisation
    @organisation = current_organisation
  end

  def current_organisation
    @current_organisation ||= Organisation.find(params[:organisation_id])
  end

  def current_territory
    @current_territory ||= current_organisation.territory
  end

  def from_modal?
    params[:modal].present?
  end

  def authorize_organisation
    # on n’utilise pas le helper authorize directement pour obliger à faire un autre appel à authorize avec la ressource qui sera réellement utilisée par l'action (par exemple le motif ou le rdv)
    Pundit.authorize(current_agent, current_organisation, :show?, policy_class: Agent::OrganisationPolicy)
  end

  attr_writer :my_agent_ids

  helper_method :my_sole_agent
  def my_sole_agent
    my_agents.first
  end

  helper_method :my_agents
  def my_agents
    return @my_agents if defined? @my_agents

    @my_agents = if @my_agent_ids
                   Agent::AgentPolicy::Scope.new(current_agent, Agent.all).resolve
                     .where(id: @my_agent_ids)
                     .order(last_name: :asc)
                     .load
                 else
                   [current_agent.id]
                 end
  end

  def set_selected_agents_in_agenda
    self.my_agent_ids = session[:selected_agent_ids_in_agenda].presence
  end
end
