# frozen_string_literal: true

class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize current_territory
  end
end
