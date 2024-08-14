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

  def with_authentication
    security [{ access_token: [], uid: [], client: [] }]

    parameter name: "access-token", in: :header, type: :string, description: "Token d'accès (authentification)", example: "SFYBngO55ImjD1HOcv-ivQ"
    parameter name: "client", in: :header, type: :string, description: "Clé client d'accès (authentification)", example: "Z6EihQAY9NWsZByfZ47i_Q"
    parameter name: "uid", in: :header, type: :string, description: "Identifiant d'accès (authentification)", example: "martine@demo.rdv-solidarites.fr"
  end

  def with_visioplainte_authentication
    with_examples
    produces "application/json"
    stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")
    let(:"X-VISIOPLAINTE-API-KEY") do # rubocop:disable RSpec/VariableName
      "visioplainte-api-test-key-123456"
    end
    security [{ "X-VISIOPLAINTE-API-KEY": [] }]
    parameter name: "X-VISIOPLAINTE-API-KEY", in: :header, type: :string, description: "Clé d'API", example: "visioplainte-api-test-key-123456", required: true
  end

  def with_shared_secret_authentication
    security [{ uid: [], "X-Agent-Auth-Signature": [] }]

    parameter name: "uid", in: :header, type: :string, description: "Identifiant d'accès (authentification)", example: "martine@demo.rdv-solidarites.fr"
    parameter name: "X-Agent-Auth-Signature", in: :header, type: :string, description: "payload crypté par le SHARED_SECRET_FOR_AGENTS_AUTH", example: "SFYBngO55ImjD1HOcv"
  end

  def with_pagination
    parameter name: "page", in: :query, type: :integer, description: "La page souhaitée", example: "1", required: false
  end
end
