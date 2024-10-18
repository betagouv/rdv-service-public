require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do # rubocop:disable RSpec/EmptyExampleGroup
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

  def self.rdv_response_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        created_at: { type: :string },
        starts_at: { type: :string },
        duration_in_min: { type: :integer },
        ends_at: { type: :string },
        guichet: { type: :object, properties: { id: { type: :integer }, name: { type: :string } } },
        user_id: { type: :integer },
      },
      required: Visioplainte::RdvBlueprint.reflections[:default].fields.keys,
    }
  end

  path "/api/visioplainte/rdvs" do
    get "Lister les rdvs" do
      with_visioplainte_authentication

      tags "Rendez-vous"
      description "Liste tous les rendez-vous, et permet de filtrer par date, par guichet, ou sur des rdv spécifiques"
      parameter name: "date_debut", in: :query, type: :string,
                description: "datetime au format iso8601. Obligatoire sauf si le paramètre ids est utilisé.\
                Permet de filtrer pour obtenir uniquement les rendez-vous qui commencent à partir de cette heure",
                example: "2024-08-19T08:00:00+02:00", required: false
      parameter name: "date_fin", in: :query, type: :string,
                description: "datetime au format iso8601.  Obligatoire sauf si le paramètre ids est utilisé.\
                Permet de filtrer pour obtenir uniquement les rendez-vous qui commencent avant cette heure",
                example: "2024-08-22T19:00:00+02:00", required: false
      parameter name: "ids[]", in: :query, type: :array,
                description: "Une liste d'ids des rendez-vous qu'on souhaite obtenir", required: false
      parameter name: "guichet_ids[]", in: :query, type: :array,
                description: "Une liste d'ids des guichets sur lesquels on veut filtrer les rendez-vous.", required: false

      response 200, "Renvoie la liste" do
        run_test!
        let(:date_debut) { "2024-08-19T08:00:00+02:00" }
        let(:date_fin) { "2024-08-20T08:00:00+02:00" }
      end
    end
    post "Prendre un rdv" do
      with_visioplainte_authentication

      tags "Rendez-vous"
      description "Crée un rdv et réserve le créneau correspondant."
      parameter name: "starts_at", in: :query, type: :string,
                description: "datetime au format iso8601. Normalement c'est une des valeurs proposées par l'endpoint de liste des créneaux.",
                example: "2024-08-19T08:00:00+02:00", required: true

      response 201, "Prend le rdv" do
        run_test!
        schema rdv_response_schema
        let(:starts_at) { "2024-08-19T08:00:00+02:00" }
      end

      response 422, "Si le créneau n'est pas disponible" do
        let(:starts_at) { "2024-11-19T08:00:00+02:00" }
        run_test!
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }, required: %w[errors]
      end
    end
  end

  path "/api/visioplainte/rdvs/{id}" do
    delete "Supprimer un rdv" do
      with_visioplainte_authentication

      tags "Rendez-vous"
      description "Supprime le rdv. Il n'apparaîtra plus dans aucune requête de l'api"

      response 204, "Supprime le rdv" do
        run_test!
        parameter name: :id, in: :path, type: :string

        let(:id) do
          post "/api/visioplainte/rdvs", params: {
            starts_at: "2024-08-19T08:00:00+02:00",
          }, headers: auth_header

          response.parsed_body["id"]
        end

        let(:auth_header) do
          { "X-VISIOPLAINTE-API-KEY" => "visioplainte-api-test-key-123456" }
        end
      end
    end
  end

  path "/api/visioplainte/rdvs/{id}/cancel" do
    put "Annuler un rdv" do
      with_visioplainte_authentication

      tags "Rendez-vous"
      description "Annule le rdv. Il apparaîtra encore dans la liste des rdv du guichet."

      response 200, "Annule le rdv" do
        run_test!
        parameter name: :id, in: :path, type: :string
        schema rdv_response_schema

        let(:id) do
          post "/api/visioplainte/rdvs", params: {
            starts_at: "2024-08-19T08:00:00+02:00",
          }, headers: auth_header

          response.parsed_body["id"]
        end

        let(:auth_header) do
          { "X-VISIOPLAINTE-API-KEY" => "visioplainte-api-test-key-123456" }
        end
      end
    end
  end
end
