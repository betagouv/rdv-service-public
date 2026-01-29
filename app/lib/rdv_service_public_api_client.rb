class RdvServicePublicApiClient
  class RequestError < StandardError; end

  def initialize(api_token)
    @api_token = api_token
  end

  def post(path, params)
    response = connection.post("/api/v1/#{path}", params)

    return response.body if response.success?

    if response.status == 422

      unless ressource_already_created_error_response?(response)
        # S'il y a une erreur métier pour autre chose que pour une erreur de création idempotente,
        # on veut qu'elle soit observable dans Sentry
        Sentry.capture_message(error_message(path, response))
      end

      # En cas d'erreur métier, on laisse le code client décider quoi faire
      return response.body
    end

    raise(RequestError, error_message(path, response))
  end

  def get(path, params = {})
    connection.get("/api/v1/#{path}", params).body
  end

  private

  def error_message(path, response)
    "échec de la requête sur #{path} (status #{response.status}). Voir les breadcrumbs Sentry pour plus d'infos"
  end

  def ressource_already_created_error_response?(response)
    external_id_errors = response.body.dig("errors", "external_id")

    external_id_errors&.find do |error_hash|
      error_hash["error"] == "taken"
    end
  end

  def connection
    url = ENV.fetch("RDV_SERVICE_PUBLIC_OAUTH_BASE_URL")
    headers = {
      "Authorization" => "Bearer #{@api_token}",
      "Content-Type" => "application/json",
    }

    @connection ||= Faraday.new(url:, headers:) do |builder|
      builder.request :json
      builder.response :json
      builder.use :sentry_breadcrumbs
    end
  end
end
