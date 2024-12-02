require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
    create(:plage_ouverture,
           organisation: orga_gendarmerie,
           agent: orga_gendarmerie.agents.first,
           motifs: orga_gendarmerie.motifs,
           first_day: Date.tomorrow,
           start_time: Tod::TimeOfDay.new(8),
           end_time: Tod::TimeOfDay.new(18),
           recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday]))
  end

  let(:orga_gendarmerie) do
    Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie") # créée dans les seeds
  end

  path "/api/visioplainte/creneaux" do
    get "Lister les créneaux disponibles" do
      with_visioplainte_authentication

      tags "Créneaux"
      description "Renvoie les créneaux disponibles"

      response 200, "Renvoie les créneaux" do
        run_test!
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

        let(:date_debut) { "2024-08-19" }
        let(:date_fin) { "2024-08-25" }

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
    end
  end

  path "/api/visioplainte/creneaux/prochain" do
    get "Indique la date du prochain créneau" do
      with_visioplainte_authentication

      tags "Créneaux"
      description "Renvoie le prochain créneau disponible"
      parameter name: "date_debut", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), date à partir de laquelle on cherche des créneaux",
                example: "2024-12-22", required: true

      let(:date_debut) { "2024-08-19" }

      response 200, "Renvoie le prochain créneau disponible" do
        run_test!
        schema type: :object, properties: { starts_at: { type: :string }, duration_in_min: { type: :integer } }, required: %w[starts_at duration_in_min]

        specify do
          expect(parsed_response_body).to eq(
            {
              starts_at: "2024-08-19T08:00:00+02:00",
              duration_in_min: 30,
            }.deep_stringify_keys
          )
        end
      end

      response 404, "Renvoie un message d'erreur si aucun créneau n'est disponible" do
        run_test!
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }, required: %w[errors]

        let(:date_debut) { "2024-11-19" }

        specify do
          expect(parsed_response_body).to eq(
            {
              errors: ["Aucun créneau n'est disponible après cette date"],
            }.deep_stringify_keys
          )
        end
      end
    end
  end
end
