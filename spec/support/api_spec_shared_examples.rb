# frozen_string_literal: true

module ApiSpecSharedExamples
  shared_context "an endpoint that returns 401 - unauthorized" do
    response 401, "Renvoie 'unauthorized' quand l'authentification est impossible" do
      let(:"access-token") { "false" }

      schema "$ref" => "#/components/schemas/error_authentication"

      run_test!
    end
  end

  shared_context "an endpoint that returns 403 - forbidden" do |details|
    response 403, "Renvoie 'forbidden' quand #{details}" do
      schema "$ref" => "#/components/schemas/error_forbidden"

      run_test!
    end
  end

  shared_context "an endpoint that returns 404 - not found" do |details|
    response 404, "Renvoie 'not_found' quand #{details}" do
      schema "$ref" => "#/components/schemas/error_not_found"

      run_test!
    end
  end

  shared_context "an endpoint that returns 422 - unprocessable_entity" do |details, document|
    response 422, "Renvoie 'unprocessable_entity' quand #{details}", document: document do
      schema "$ref" => "#/components/schemas/error_unprocessable_entity"

      run_test!
    end
  end

  shared_context "an endpoint that returns 429 - too_many_requests" do |method, path|
    response 429, "Renvoie 'too_many_requests' quand la limite d'appels est atteinte" do
      schema "$ref" => "#/components/schemas/error_too_many_request"

      before do
        Rack::Attack.enabled = true
        Rack::Attack.reset!
        3.times do
          send(method, path)
        end
      end

      run_test!
    end
  end

  shared_context "rdv_mairie_api_authentication", :rdv_mairie_api_authentication do
    around do |example|
      previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]
      ENV["ANTS_API_AUTH_TOKEN"] = ""

      example.run

      ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
    end
  end
end
