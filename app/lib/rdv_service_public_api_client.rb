class RdvServicePublicApiClient
  class RequestError < StandardError; end

  def initialize(api_token, refresh_token = nil, on_token_refresh: nil)
    @api_token = api_token
    @refresh_token = refresh_token
    @on_token_refresh = on_token_refresh
  end

  def post(path, params)
    response = connection.post("/api/v1/#{path}", params)

    if response.status == 401 && @on_token_refresh
      refresh_token!

      response = connection.post("/api/v1/#{path}", params)
    end

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
    response = connection.get("/api/v1/#{path}", params)

    if response.status == 401 && @on_token_refresh
      refresh_token!

      connection.get("/api/v1/#{path}", params).body
    else
      response.body
    end
  end

  private

  def error_message(path, response)
    "échec de la requête sur #{path} (status #{response.status}). Voir les breadcrumbs Sentry pour plus d'infos"
  end

  def ressource_already_created_error_response?(response)
    external_id_errors = Array(response.body.dig("errors", "external_id")) + Array(response.body.dig("errors", "external_references.external_id"))

    external_id_errors.any? do |error_hash|
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

  def refresh_token!
    client = OAuth2::Client.new(
      ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_ID"],
      ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET"],
      site: ENV["RDV_SERVICE_PUBLIC_OAUTH_BASE_URL"]
    )

    old_token = OAuth2::AccessToken.new(client, @api_token, refresh_token: @refresh_token)

    new_token = old_token.refresh!

    @api_token = new_token.token
    @refresh_token = new_token.refresh_token
    @connection = nil # L'objet connection précédent avait encore l'api_token expiré en header, donc on doit en reconstruire un
    @on_token_refresh.call(new_token.token, new_token.refresh_token)
  end
end
