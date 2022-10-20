# frozen_string_literal: true

class Api::V1::BaseController < ActionController::Base
  include Api::V1::ResourcesRenderer
  respond_to :json

  protected

  def check_parameters_presence(*parameters)
    missing_parameters = parameters.select { |param| params[param].blank? }
    render_error :bad_request, missing: missing_parameters.to_sentence if missing_parameters.any?
  end

  def render_error(status, error = { error: :unknown })
    render json: error, status: status
  end
end
