class Api::Visioplainte::GuichetsController < Api::Visioplainte::BaseController
  def self.guichets
    Agent.joins(roles: { organisation: :territory }).where(territories: { name: Territory::VISIOPLAINTE_NAME })
      .where(roles: { access_level: AgentRole::ACCESS_LEVEL_INTERVENANT })
      .joins(:services).where(services: { name: gendarmerie_service_name })
  end

  def index
    render json: {
      guichets: self.class.guichets.map do |intervenant|
        {
          id: intervenant.id,
          name: intervenant.full_name,
        }
      end,
    }
  end
end
