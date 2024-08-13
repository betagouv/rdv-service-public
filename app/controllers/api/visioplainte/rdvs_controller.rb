class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def create
    # Des données de test pour documenter l'api.
    rdv = Rdv.new(
      id: 123,
      users: [User.new(id: 456)],
      agents: [Agent.new(id: 789)],
      created_at: Time.zone.now,
      starts_at: params[:starts_at],
      duration_in_min: 45
    )

    render json: Visioplainte::RdvBlueprint.render(rdv), status: :created
  end
end
