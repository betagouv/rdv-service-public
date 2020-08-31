class Admin::Departements::SetupChecklistsController < AgentDepartementAuthController
  def show
    authorize(policy_scope(Organisation).where(departement: current_departement.number).first)
  end
end
