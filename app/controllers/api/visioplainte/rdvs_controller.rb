class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def create
    render json: Visioplainte::RdvBlueprint.render(rdv(:unknown)), status: :created
  end

  def destroy
    head :no_content
  end

  def cancel
    render json: Visioplainte::RdvBlueprint.render(rdv(:excused)), status: :ok
  end

  def rdv(status)
    # Des données de test pour documenter l'api.
    Rdv.new(
      id: 123,
      users: [User.new(id: 456)],
      agents: [Agent.new(id: 789, last_name: "Guichet 3")],
      created_at: Time.zone.now,
      starts_at: params[:starts_at],
      duration_in_min: 45,
      status: status
    )
  end
end
