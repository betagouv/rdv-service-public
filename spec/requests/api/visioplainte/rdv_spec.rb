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

        parameter name: "starts_at", in: :query, type: :string, description: "datetime au format iso8601 (YYYY-MM-DD)"
        schema type: :object,
               properties: {
                 id: { type: :integer },

               },
               required: Visioplainte::RdvBlueprint.reflections[:default].fields.keys

        let(:starts_at) { Time.zone.now.iso8601 }
        let(:service) { "Police" }
      end
    end
  end
end
