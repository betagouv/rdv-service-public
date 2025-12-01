class Operators::EspacesController < OperatorController
  after_action :verify_authorized, except: :index

  def index
    territories = Territory.where(operator_id: current_operator_manager.operator_id)

    render locals: { territories: }
  end

  def show
    # TODO: Add policy!
    territory = Territory.find(params[:id])
    authorize(territory, policy_class: OperatorManager::TerritoryPolicy)

    render locals: { territory: }
  end
end
