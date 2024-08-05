class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize_agent current_territory
  end

  private

  def pundit_user
    current_agent
  end
end
