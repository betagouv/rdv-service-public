class Admin::Territories::SectorizationsController < Admin::Territories::BaseController
  def show
    skip_authorization
  end
end
