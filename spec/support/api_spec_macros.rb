module ApiSpecMacros
  def with_examples
    after do |example|
      content = example.metadata[:response][:content] || {}
      example_spec = {
        "application/json" => {
          examples: {
            example: {
              value: response.body.present? ? JSON.parse(response.body, symbolize_names: true) : "",
            },
          },
        },
      }
      example.metadata[:response][:content] = content.deep_merge(example_spec)
    end
  end

  def with_oauth_token_authentication
    parameter name: "content-type", in: :header, type: :string, example: "application/json"
    parameter name: "authorization", in: :header, type: :string, description: "Token d'accès (authentification)", example: "Bearer 123456"
    let(:"content-type") { "application/json" }
    let(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
    let(:authorization) { "Bearer #{oauth_token.plaintext_token}" }

    produces "application/json" # Ces deux appels ne sont pas strictement liés à l'authentification, mais permettent de rendre les specs moins verbeuses
    consumes "application/json"
  end

  def with_visioplainte_authentication
    with_examples
    produces "application/json"
    consumes "application/json"
    stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")
    let(:"X-VISIOPLAINTE-API-KEY") do
      "visioplainte-api-test-key-123456"
    end
    security [{ "X-VISIOPLAINTE-API-KEY": [] }]
    parameter name: "X-VISIOPLAINTE-API-KEY", in: :header, type: :string, description: "Clé d'API", example: "visioplainte-api-test-key-123456", required: true
  end

  def with_rdv_insertion_oauth_authentication
    include_context "with rdv-insertion OAuth authentication"

    parameter name: "authorization", in: :header, type: :string, description: "Token d'accès OAuth de l'application rdv-insertion", example: "Bearer 123456"
    let(:authorization) { auth_headers[:Authorization] }
  end

  def with_pagination
    parameter name: "page", in: :query, type: :integer, description: "La page souhaitée", example: "1", required: false
  end
end
