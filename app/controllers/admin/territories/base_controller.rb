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
    AgentTerritorialContext.new(current_agent, current_territory)
  end
  helper_method :pundit_user

  def authorize(record, *args)
    # Utilisation d'un namespace `configuration` pour éviter les confusions avec les policies d'un RDV usager, d'un RDV agent ou d'un RDV en configuration.
    super([:configuration, record], *args)
  end

  # L'usage recommandé est de passer explicitement une policy_scope_class pour savoir quelle policy est utilisé
  # A terme, on voudra forcer l'argument policy_scope_class
  def policy_scope(scope, policy_scope_class: nil)
    # Utilisation d'un namespace `configuration` pour éviter les confusions avec les policies d'un RDV usager, d'un RDV agent ou d'un RDV en configuration.
    if policy_scope_class
      super(scope, policy_scope_class: policy_scope_class)
    else
      super([:configuration, scope])
    end
  end

  private

  def set_territory
    @territory = Territory.find(params[:territory_id])
  end
end
