class Api::Visioplainte::RdvsController < Api::Visioplainte::BaseController
  def create
    render json: Visioplainte::RdvBlueprint.render(Rdv.new(id: 123)), status: :created
  end
end
