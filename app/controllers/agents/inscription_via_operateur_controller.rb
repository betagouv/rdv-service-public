class Agents::InscriptionViaOperateurController < AgentAuthController
  layout "application"

  def show
    skip_authorization

    operator_name, signup_url = session.delete(:inscription_via_operateur)&.values_at("operator_name", "signup_url")
    if operator_name.present? && signup_url.present?
      Sentry.capture_message(
        "ProConnectOnboardingRouter: agent invité à s'inscrire via son opérateur",
        level: "info",
        extra: { agent_id: current_agent.id, operator_name: }
      )
      render locals: { operator_name:, signup_url: }
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
