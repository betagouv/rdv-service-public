class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end
end
