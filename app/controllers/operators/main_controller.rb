class Operators::MainController < OperatorController
  skip_before_action :authenticate_operator_manager!, only: :index

  def index
    redirect_to operators_espaces_path if operator_manager_signed_in?
  end
end
