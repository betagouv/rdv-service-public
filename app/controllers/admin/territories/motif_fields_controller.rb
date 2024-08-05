class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize_agent current_territory
  end
end
