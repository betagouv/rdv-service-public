class OperatorController < ApplicationController
  layout "application_operator"

  before_action :authenticate_operator_manager!

  rescue_from Pundit::NotAuthorizedError, with: :operator_not_authorized

  def pundit_user
    current_operator_manager
  end

  private

  def operator_not_authorized
    flash[:error] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_to operators_root_path
  end
end
