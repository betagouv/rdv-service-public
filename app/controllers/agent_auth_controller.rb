class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent"

  before_action :authorize_organisation, if: -> { params[:organisation_id].present? }
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  before_action :clear_session_hide_sidebar, if: -> { params[:clear_session_hide_sidebar].present? }
  before_action :clear_session_current_rdv_plan, if: -> { params[:clear_session_current_rdv_plan].present? }

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
    # on n’utilise pas le helper authorize directement car le pundit_user défini plus haut a comme contexte
    # l’organisation elle même, ici on veut un contexte d’agent sans organisation
    Pundit.authorize(AgentContext.new(current_agent), current_organisation, :show?, policy_class: Agent::OrganisationPolicy)
  end

  def clear_session_hide_sidebar
    session.delete(:hide_sidebar)
  end

  def clear_session_current_rdv_plan
    session.delete(:current_rdv_plan)
  end
end
