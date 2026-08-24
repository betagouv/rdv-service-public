class Admin::Territories::CalendarSettingsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    current_territory.update(params.require(:territory).permit(:work_on_sunday))
    flash[:success] = "Configuration de calendrier enregistrée"
    redirect_to action: :edit
  end
end
