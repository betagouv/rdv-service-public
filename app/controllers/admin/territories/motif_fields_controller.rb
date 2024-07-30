class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize_with_legacy_configuration_scope current_territory
  end
end
