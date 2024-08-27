require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  path "/api/visioplainte/rdvs" do
    post "Prendre un rdv" do
      with_visioplainte_authentication

      description "Crée un rdv et réserve le créneau correspondant."
      parameter name: :service, in: :query, type: :string,
                description: "Indique si on souhaite prendre rendez-vous avec la gendarmerie ou la police. " \
                             "Les deux valeurs possibles sont donc 'Police' ou 'Gendarmerie'",
                example: "Police", required: true

      parameter name: "starts_at", in: :query, type: :string,
                description: "datetime au format iso8601. Normalement c'est une des valeurs proposées par l'endpoint de liste des créneaux.",
                example: "2024-08-19T08:00:00+02:00", required: true

      let(:service) { "Police" }

      response 201, "Prend le rdv" do
        run_test!
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 created_at: { type: :string },
                 starts_at: { type: :string },
                 duration_in_min: { type: :integer },
                 ends_at: { type: :string },
                 guichet: { type: :object, properties: { id: { type: :integer }, name: { type: :string } } },
                 user_id: { type: :integer },
               },
               required: Visioplainte::RdvBlueprint.reflections[:default].fields.keys

        let(:starts_at) { "2024-08-19T08:00:00+02:00" }
      end

      response 422, "Si le créneau n'est pas disponible" do
        let(:starts_at) { "2024-11-19T08:00:00+02:00" }
        run_test!
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }, required: %w[errors]
      end
    end
  end

  let(:id) { rdv.id }
  let(:rdv) { create(:rdv) }

  path "/api/visioplainte/rdvs/{id}" do
    delete "Supprimer un rdv" do
      with_visioplainte_authentication

      description "Supprime le rdv. Il n'apparaîtra plus dans aucune requête de l'api"

      response 204, "Supprime le rdv" do
        run_test!
        parameter name: :id, in: :path, type: :string
      end
    end
  end

  path "/api/visioplainte/rdvs/{id}/cancel" do
    put "Annuler un rdv" do
      with_visioplainte_authentication

      description "Annule le rdv. Il apparaîtra encore dans la liste des rdv du guichet."

      response 200, "Annule le rdv" do
        run_test!
        parameter name: :id, in: :path, type: :string
      end
    end
  end
end
