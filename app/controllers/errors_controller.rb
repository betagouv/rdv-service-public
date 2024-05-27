class ErrorsController < ApplicationController
  layout "application_dsfr"

  def not_found
    render status: :not_found
  end
end
