class AgentDepartementAuthController < AgentAuthController
  before_action :set_departement
  layout "application_agent_departement"

  def current_departement
    @departement
  end
  helper_method :current_departement

  private

  def set_departement
    @departement = Departement.new(params[:departement_id])
    raise Pundit::NotAuthorizedError unless \
      current_agent.organisations.where(departement: @departement.number).any?
  end
end
