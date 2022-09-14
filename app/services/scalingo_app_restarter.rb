# frozen_string_literal: true

# Service to restart scalingo app
# call only when deploying on scalingo
class ScalingoAppRestarter < BaseService
  class ApiError < StandardError; end

  # Restarts all the containers of the target app.
  # See https://github.com/betagouv/rdv-solidarites.fr/issues/1866
  def initialize(app_id, api_token)
    @app_id = app_id
    @api_token = api_token
  end

  def perform
    # https://developers.scalingo.com/apps#restart-an-application
    # First get a bearer token from the API token
    token_response = Typhoeus::Request.post(
      "https://auth.scalingo.com/v1/tokens/exchange",
      userpwd: ":#{@api_token}",
      headers: { "Content-Type": "application/json",
                 Accept: "application/json", }
    )

    raise ApiError, "Token request failed: #{token_response.code}" unless token_response.success?

    json = JSON.parse(token_response.body)
    bearer_token = json["token"]

    # Then perform the actual restart
    api_host = "api.osc-secnum-fr1.scalingo.com"
    restart_response = Typhoeus::Request.post(
      "https://#{api_host}/v1/apps/#{@app_id}/restart",
      headers: { "Content-Type": "application/json",
                 Accept: "application/json",
                 Authorization: "Bearer #{bearer_token}", }
    )

    raise ApiError, "Restart request failed: #{restart_response.code}" unless restart_response.success?
  end
end
