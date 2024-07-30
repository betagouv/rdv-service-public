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

  def authorize_with_legacy_configuration_scope(record, *args, **kwargs)
    # L'utilisation de configuration est un legacy qui a l'inconvénient de distinguer les permissions en fonction de la page sur laquelle on est en train de naviguer
    # On préfère que le controller applique le filtre pertinent, et que les policy indiquent les permissions dans l'absolu, indépendamment de la page courante.
    authorize([:configuration, record], *args, **kwargs)
  end

  # L'usage recommandé est de passer explicitement une policy_scope_class pour savoir quelle policy est utilisé
  # A terme, on voudra forcer l'argument policy_scope_class
  def policy_scope(scope, policy_scope_class: nil)
    if policy_scope_class
      super(scope, policy_scope_class: policy_scope_class)
    else
      # L'utilisation de configuration est un legacy qui a l'inconvénient de distinguer les permissions en fonction de la page sur laquelle on est en train de naviguer
      # On préfère que le controller applique le filtre pertinent, et que les policy indiquent les permissions dans l'absolu, indépendamment de la page courante.
      super([:configuration, scope])
    end
  end

  private

  def set_territory
    @territory = Territory.find(params[:territory_id])
  end
end
