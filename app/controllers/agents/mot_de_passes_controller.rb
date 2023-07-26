# frozen_string_literal: true

# Contrairement au Agents::PasswordsController qui gère les reset de mot de passe via les mécanismes custom de devise
# et qui ne nécessite pas que l'agent soit connecté,
# ce controller gère la modification de mot de passe pour un agent connecté, sans utiliser Devise.
class Agents::MotDePassesController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"

  def edit
    authorize current_agent
  end

  def update
    authorize current_agent
    if current_agent.update_with_password(agent_params)
      flash[:notice] = "Votre mot de passe a été changé"
      redirect_to edit_agent_registration_path
    else
      render :edit
    end
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end

  def agent_params
    params.require(:agent).permit(:password, :password_confirmation, :current_password)
  end
end
