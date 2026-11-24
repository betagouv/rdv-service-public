class Admin::Territories::SecuritySettingsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    current_territory.update!(params.require(:territory).permit(:force_2fa_for_agents))

    flash[:success] = "Paramètres de sécurité enregistrés"
    redirect_to action: :edit
  end
end
