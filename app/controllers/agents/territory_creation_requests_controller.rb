class Agents::TerritoryCreationRequestsController < AgentAuthController
  layout "application"
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

  def permitted_params
    params.require(:territory_creation_request).permit(:territory_name, :organisation_name, :service_name)
  end

  def pundit_user
    current_agent
  end
end
