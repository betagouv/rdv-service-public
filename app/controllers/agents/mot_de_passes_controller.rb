# Contrairement au Agents::PasswordsController qui gère les reset de mot de passe via les mécanismes custom de devise
# et qui ne nécessite pas que l'agent soit connecté,
# ce controller gère la modification de mot de passe pour un agent connecté, sans utiliser Devise.
class Agents::MotDePassesController < AgentAuthController
  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :compte }

  def edit
    authorize(current_agent, policy_class: Agent::AgentPolicy)
  end

  def update
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    if current_agent.update_with_password(agent_params)
      bypass_sign_in(current_agent) # Pour des raisons mystérieuses, Devise déconnecte l'agent après un changement de mot de passe
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
