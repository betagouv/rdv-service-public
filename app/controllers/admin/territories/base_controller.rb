class Admin::Territories::BaseController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_configuration"

  before_action :set_territory

  # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :verify_authorized, except: %i[index search]
  after_action :verify_policy_scoped, only: %i[index search]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  def current_territory
    @territory
  end
  helper_method :current_territory

  def pundit_user
    current_agent
  end
  helper_method :pundit_user

  # L'usage recommandé est de passer explicitement une policy_scope_class pour savoir quelle policy est utilisé
  def policy_scope(scope, policy_scope_class:)
    super(scope, policy_scope_class: policy_scope_class)
  end

  private

  def set_territory
    @territory = Territory.find(params[:territory_id])

    # On instancie une policy plutôt que d'appeler authorize pour ne pas neutraliser le `verify_authorized`
    unless Agent::TerritoryPolicy.new(current_agent, @territory).show?
      raise Pundit::NotAuthorizedError, "not authorized"
    end

    @territory
  end
end
