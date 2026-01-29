class ErrorsController < ApplicationController
  def bad_request
    render status: :bad_request, layout: rendered_layout
  end

  def not_found
    render status: :not_found, layout: rendered_layout
  end

  def internal_server_error
    render status: :internal_server_error, layout: rendered_layout
  end

  private

  def rendered_layout
    # Le layout application_configuration permet d'avoir le header des agents sans le menu de gauche
    current_agent ? "application_configuration" : "application"
  end
end
