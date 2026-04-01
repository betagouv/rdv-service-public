class Agents::InscriptionViaOperateurController < AgentAuthController
  layout "application"

  def show
    skip_authorization

    if params[:operator_name].present? && params[:signup_url].present?
      render locals: { operator_name: params[:operator_name], signup_url: params[:signup_url] }
    else
      flash[:error] = "Une erreur est survenue lors de la récupération des informations de votre opérateur. Nous vous invitons à contacter leur support."
      redirect_to root_path
    end
  end

  private

  def pundit_user
    current_agent
  end
end
