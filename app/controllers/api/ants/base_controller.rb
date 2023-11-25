# API de mise à disposition pour le moteur de recherche de l'ANTS
class Api::Ants::BaseController < ActionController::Base
  respond_to :json

  before_action :check_authentication_token!
  before_action :add_sentry_crumb

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

  def add_sentry_crumb
    Sentry.add_breadcrumb(
      Sentry::Breadcrumb.new(
        message: "ANTS API Request details",
        data: {
          method: request.method,
          url: request.url,
          headers: request.headers,
          params: params,
        }
      )
    )
  end
end
