class Operators::ConfigurationController < OperatorController
  after_action :verify_authorized, except: :index

  def index
    operator = current_operator_manager.operator

    render locals: { operator: }
  end
end
