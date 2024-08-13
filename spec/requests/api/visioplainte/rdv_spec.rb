require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")
  let(:"X-VISIOPLAINTE-API-KEY") do # rubocop:disable RSpec/VariableName
    "visioplainte-api-test-key-123456"
  end

  path "/api/visioplainte/rdvs" do
    post "Prendre un rdv" do
      produces "application/json"

      description "Crée un rdv et réserve le créneau correspondant. Le rdv pourra être supprimé si l'usager ne le confirme pas, ou annulé si l'usager prévient d'une absence"
      with_examples
      with_visioplainte_authentication

      response 201, "Prend le rdv" do
        run_test!
        parameter name: :service, in: :query, type: :string,
                  description: "Indique si on souhaite obtenir les créneaux de la plateforme de la gendarmerie ou de la police. " \
                               "Les deux valeurs possibles sont donc 'Police' ou 'Gendarmerie'",
                  example: "Police", required: true

        parameter name: "date_debut", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), premier jour de la liste de créneaux qu’on renverra", example: "2024-12-22"
        parameter name: "date_fin", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), dernier jour de la liste de créneaux qu’on renverra (inclus dans les résultats)",
                  example: "2024-12-28"

        schema type: :object,
               properties: {
                 id: { type: :integer },
               },
               required: %w[id starts_at created_at duration_in_min users guichet]

        let(:service) { "Police" }
        specify do
          expect(parsed_response_body).to eq(
            {
              creneaux: [
                {
                  starts_at: "2024-12-22T10:00:00+02:00",
                  duration_in_min: 30,
                },
                {
                  starts_at: "2024-12-22T10:30:00+02:00",
                  duration_in_min: 30,
                },
                {
                  starts_at: "2024-12-22T11:00:00+02:00",
                  duration_in_min: 30,
                },
              ],
            }.deep_stringify_keys
          )
        end
      end
    end
  end
end
