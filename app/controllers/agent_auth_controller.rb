class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent"

  before_action :authorize_organisation, if: -> { params[:organisation_id].present? }
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation, :current_territory, :policy_scope, :from_modal?, :latest_used_organisation_id

  private

  def pundit_user
    @pundit_user ||= AgentOrganisationContext.new(current_agent, current_organisation)
  end
  helper_method :pundit_user

  def set_organisation
    @organisation = current_organisation
  end

  def current_agent
    super.tap { _1&.preload_roles }
  end

  def current_organisation
    return @current_organisation if defined? @current_organisation

    @current_organisation = Organisation.find(params[:organisation_id]).tap do |organisation|
      session[:latest_used_organisation_id] = organisation.id if organisation
    end
  end

  def current_territory
    @current_territory ||= current_organisation.territory
  end

  def from_modal?
    params[:modal].present?
  end

  def latest_used_organisation_id
    session[:latest_used_organisation_id] if current_agent.organisation_ids.include?(session[:latest_used_organisation_id])
  end

  def authorize_organisation
    # on n’utilise pas le helper authorize directement pour obliger à faire un autre appel à authorize avec la ressource qui sera réellement utilisée par l'action (par exemple le motif ou le rdv)
    Pundit.authorize(current_agent, current_organisation, :show?, policy_class: Agent::OrganisationPolicy)
  end
end
