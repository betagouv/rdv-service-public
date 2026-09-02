class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  include Agents::SessionConcern

  layout "application_agent"

  before_action :authorize_organisation, if: :current_organisation
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

  def current_agent
    super.tap { _1&.preload_roles }
  end

  def current_organisation
    return @current_organisation if defined?(@current_organisation)

    # Le param `:organisation_id` qui nous intéresse est forcément dans le path puisque les
    # routes de notre interface orga-centric sont imbriquées dans `resources :organisations`.
    path_org_id = request.path_parameters[:organisation_id].presence&.to_i
    return unless path_org_id

    @current_organisation = Organisation.find(path_org_id).tap do |found_org|
      agent_session[:latest_used_organisation_id] = found_org.id if found_org
    end
  end

  def current_territory
    @current_territory ||= current_organisation&.territory
  end

  def from_modal?
    params[:modal].present?
  end

  def authorize_organisation
    # on n’utilise pas le helper authorize directement pour obliger à faire un autre appel à authorize avec la ressource qui sera réellement utilisée par l'action (par exemple le motif ou le rdv)
    Pundit.authorize(current_agent, current_organisation, :show?, policy_class: Agent::OrganisationPolicy)
  end
end
