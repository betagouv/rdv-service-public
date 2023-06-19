# frozen_string_literal: true

class Api::Ants::BaseController < ActionController::Base
  respond_to :json

  before_action :check_authentication_token!

  private

  def check_authentication_token!
    return if matching_authentication_token?

    render(
      status: :unauthorized,
      json: { error: "X-HUB-RDV-AUTH-TOKEN header is missing or invalid" }.to_json
    )
  end

  def matching_authentication_token?
    ActiveSupport::SecurityUtils.secure_compare(authentication_token, ENV["ANTS_API_AUTH_TOKEN"])
  end

  def authentication_token
    request.headers.fetch("X-HUB-RDV-AUTH-TOKEN", "")
  end
end
