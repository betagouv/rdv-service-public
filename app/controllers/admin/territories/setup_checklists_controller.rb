class Admin::Territories::SetupChecklistsController < Admin::Territories::BaseController
  def show
    authorize_admin(current_territory)
  end
end
