class Operators::MainController < OperatorController
  skip_before_action :authenticate_operator_manager!, only: :index

  def index; end
end
