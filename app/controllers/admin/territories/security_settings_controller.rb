class Admin::Territories::SecuritySettingsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    current_territory.update(params.require(:territory).permit(:force_2fa_for_agents))

    if current_territory.saved_change_to_force_2fa_for_agents?
      Territories::RefreshAgentsSensitiveAccountJob.perform_later(current_territory)
    end

    flash[:success] = "Paramètres de sécurité enregistrés"
    redirect_to action: :edit
  end
end
