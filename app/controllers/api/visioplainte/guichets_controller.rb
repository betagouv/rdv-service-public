class Api::Visioplainte::GuichetsController < Api::Visioplainte::BaseController
  def index
    intervenants = Agent.joins(roles: { organisation: :territory }).where(territories: { name: Territory::VISIOPLAINTE_NAME })
      .where(roles: { access_level: AgentRole::ACCESS_LEVEL_INTERVENANT })
      .joins(:services).where(services: { name: Api::Visioplainte::CreneauxController::SERVICE_NAMES["Gendarmerie"] })

    render json: {
      guichets: intervenants.map do |intervenant|
        {
          id: intervenant.id,
          name: intervenant.full_name,
        }
      end,
    }
  end
end
