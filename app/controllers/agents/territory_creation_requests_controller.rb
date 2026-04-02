class Agents::TerritoryCreationRequestsController < AgentAuthController
  layout "application"
  before_action :redirect_if_opsn_restricted

  def new
    authorize(TerritoryCreationRequest.new, policy_class: Agent::TerritoryCreationRequestPolicy)
    @territory_creation_request = TerritoryCreationRequest.new
  end

  def create
    @territory_creation_request = TerritoryCreationRequest.new(permitted_params.merge(agent_id: current_agent.id))
    authorize(@territory_creation_request, policy_class: Agent::TerritoryCreationRequestPolicy)

    if @territory_creation_request.save
      flash[:success] = "Votre demande a bien été enregistrée. Notre équipe va l'étudier et revenir vers vous dans les meilleurs délais"
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def redirect_if_opsn_restricted
    return unless current_domain.allow_self_onboarding
    return unless current_agent.agent_territorial_access_rights.none?

    result = ProConnectOnboardingRouter.new(current_agent, current_domain).call

    case result.action
    when :contact_admin
      flash[:info] = "Votre organisation est rattachée à un espace RDV Service Public, mais vous n'avez pas les droits " \
                     "d'administrateur. Rapprochez-vous de votre administrateur pour qu'il vous accorde les accès sur votre espace."
      redirect_to authenticated_agent_root_path
    when :signup_via_operator
      redirect_to agents_inscription_via_operateur_path(signup_url: result.signup_url, operator_name: result.operator_name)
    end
  end

  def permitted_params
    params.require(:territory_creation_request).permit(:territory_name, :organisation_name, :service_name)
  end

  def pundit_user
    current_agent
  end
end
