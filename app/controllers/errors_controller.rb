class ErrorsController < ApplicationController
  def not_found
    rendered_layout = current_agent ? "application_configuration" : "application"
    render status: :not_found, layout: rendered_layout
  end
end
