require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  def self.guichet_response_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
      },
      required: %i[id name],
    }
  end

  path "/api/visioplainte/guichets" do
    get "Les guichets représentent des postes physiques. Il est possible d'ouvrir une plage d'ouverture pour un guichet. Un rdv est associé à un guichet" do
      with_visioplainte_authentication

      response 200, "Renvoie la liste des guichets" do
        run_test!
        parameter name: :service, in: :query, type: :string,
                  description: "Indique si on souhaite obtenir les créneaux de la plateforme de la gendarmerie ou de la police. " \
                               "Les deux valeurs possibles sont donc 'Police' ou 'Gendarmerie'",
                  example: "Gendarmerie", required: true

        let(:service) { "Gendarmerie" }
        specify do
          guichets = parsed_response_body["guichets"]
          expect(guichets).to contain_exactly(
            {
              "id" => anything, name: "GUICHET 1",
            },
            {

              "id" => anything, name: "GUICHET 2",
            }
          )
        end
      end
    end
  end
end
