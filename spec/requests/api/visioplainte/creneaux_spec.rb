require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  path "/api/visioplainte/creneaux" do
    get "Lister les créneaux disponibles" do
      with_visioplainte_authentication

      description "Renvoie les créneaux disponibles"

      response 200, "Renvoie les créneaux" do
        run_test!
        parameter name: :service, in: :query, type: :string,
                  description: "Indique si on souhaite obtenir les créneaux de la plateforme de la gendarmerie ou de la police. " \
                               "Les deux valeurs possibles sont donc 'Police' ou 'Gendarmerie'",
                  example: "Police", required: true

        parameter name: "date_debut", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), premier jour de la liste de créneaux qu’on renverra",
                  example: "2024-12-22", required: true
        parameter name: "date_fin", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), dernier jour de la liste de créneaux qu’on renverra (inclus dans les résultats)",
                  example: "2024-12-28", required: true

        schema type: :object,
               properties: {
                 creneaux: { type: :array, items: {
                   type: :object, properties: { starts_at: { type: :string }, duration_in_min: { type: :integer } },
                 }, },
               },
               required: ["creneaux"]

        let(:service) { "Police" }
        let(:date_debut) { "2024-08-19" }
        let(:date_fin) { "2024-08-25" }

        context "Police" do
          let(:service) { "Police" }

          specify do
            creneaux = parsed_response_body["creneaux"]
            expect(creneaux.first.symbolize_keys).to eq(
              {
                starts_at: "2024-08-19T08:00:00+02:00",
                duration_in_min: 30,
              }
            )
          end
        end

        context "Gendarmerie" do
          let(:service) { "Gendarmerie" }

          specify do
            creneaux = parsed_response_body["creneaux"]
            expect(creneaux).to be_empty
          end
        end
      end
    end
  end
end
