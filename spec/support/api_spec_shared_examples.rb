# frozen_string_literal: true

module ApiSpecSharedExamples
  shared_context "an authenticated endpoint" do
    response 401, "Renvoie 'unauthorized' quand l'authentification est impossible" do
      let(:"access-token") { "false" }

      schema "$ref" => "#/components/schemas/error_authentication"

      run_test!
    end
  end
end
