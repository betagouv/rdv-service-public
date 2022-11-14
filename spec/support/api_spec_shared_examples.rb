# frozen_string_literal: true

module ApiSpecSharedExamples
  shared_context "an authenticated endpoint" do
    response 401, "Renvoie 'unauthorized' quand l'authentification est impossible" do
      let(:"access-token") { "false" }

      schema "$ref" => "#/components/schemas/error_authentication"

      run_test!
    end
  end

  shared_context "a rate limited endpoint" do |method, path|
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
end
