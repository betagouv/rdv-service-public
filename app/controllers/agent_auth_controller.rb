class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent"

  before_action :authorize_organisation, if: -> { params[:organisation_id].present? }
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation, :current_territory, :policy_scope, :from_modal?

  private

  def pundit_user
    @pundit_user ||= AgentOrganisationContext.new(current_agent, current_organisation)
  end
  helper_method :pundit_user

  def authorize(record, *args, **kwargs)
    super([:agent, record], *args, **kwargs)
  end

  # L'usage recommandé est de passer explicitement une policy_scope_class pour savoir quelle policy est utilisé
  # A terme, on voudra forcer l'argument policy_scope_class
  def policy_scope(scope, policy_scope_class: nil)
    if policy_scope_class
      super(scope, policy_scope_class: policy_scope_class)
    else
      super([:agent, scope])
    end
  end

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
    # on ne peut pas utiliser authorize car le pundit_user défini plus haut a comme contexte
    # l’organisation elle même, ici on veut un contexte d’agent sans organisation
    policy = Agent::OrganisationPolicy.new(AgentContext.new(current_agent), current_organisation)
    raise Pundit::NotAuthorizedError unless policy.link_to_organisation?
  end
end
