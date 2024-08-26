RSpec.describe "Creneaux" do
  subject(:get_request) do
    get "/api/visioplainte/creneaux", headers: auth_header, params: creneaux_params
    JSON.parse(response.body).deep_symbolize_keys
  end

  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")

  let(:auth_header) do
    { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-123456" }
  end

  context "when there are available créneaux" do
    let(:creneaux_params) do
      {
        service: "Police",
        date_debut: "2024-08-19",
        date_fin: "2024-08-25",
      }
    end

    it "returns a list of creneaux" do
      creneaux = get_request[:creneaux]
      expect(creneaux.first).to eq(
        {
          starts_at: "2024-08-19T08:00:00+02:00",
          duration_in_min: 30,
        }
      )
    end
  end

  describe "service param" do
    let(:creneaux_params) do
      {
        service: "Gendarmerie",
        date_debut: "2024-08-19",
        date_fin: "2024-08-25",
      }
    end

    it "allows to get Gendarmerie creneaux as well" do
      creneaux = get_request[:creneaux]
      expect(creneaux.first).to eq(
        {
          starts_at: "2024-08-19T14:00:00+02:00",
          duration_in_min: 30,
        }
      )
    end
  end

  describe "date de début et de fin" do
    let(:creneaux_params) do
      {
        service: "Police",
        date_debut: "2024-08-19",
        date_fin: "2024-08-19",
      }
    end

    it "returns the creneaux included on the last day" do
      creneaux = get_request[:creneaux]
      expect(creneaux.count).to eq 8
      expect(creneaux.first[:starts_at]).to eq "2024-08-19T08:00:00+02:00"
      expect(creneaux.last[:starts_at]).to eq "2024-08-19T11:30:00+02:00"
    end

    context "when date_debut is missing" do
      let(:creneaux_params) do
        {
          service: "Police",
          date_fin: "2024-08-19",
        }
      end

      it "returns a 400 error" do
        expect(get_request).to eq(
          { errors: ["Paramètre date_debut manquant"] }
        )
        expect(response.status).to eq 400
      end
    end

    context "when asking for a too big range" do
      let(:creneaux_params) do
        {
          service: "Police",
          date_debut: "2024-08-19",
          date_fin: "2024-10-19",
        }
      end

      it "returns a 400 error so that we don't compute too many availabilities" do
        expect(get_request).to eq(
          { errors: ["date_debut et date_fin ne doivent pas être espacés de plus de 31 jours"] }
        )
        expect(response.status).to eq 400
      end
    end
  end

  path "/api/visioplainte/creneaux/prochain" do
    get "Indique la date du prochain créneau" do
      with_visioplainte_authentication

      description "Renvoie le prochain créneau disponible"
      parameter name: :service, in: :query, type: :string,
                description: "Indique si on souhaite obtenir les créneaux de la plateforme de la gendarmerie ou de la police. " \
                             "Les deux valeurs possibles sont donc 'Police' ou 'Gendarmerie'",
                example: "Police", required: true

      parameter name: "date_debut", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), date à partir de laquelle on cherche des créneaux",
                example: "2024-12-22", required: true

      let(:date_debut) { "2024-12-22" }
      let(:service) { "Police" }

      response 200, "Renvoie le prochain créneau disponible" do
        run_test!
        schema type: :object, properties: { starts_at: { type: :string }, duration_in_min: { type: :integer } }, required: %w[starts_at duration_in_min]

        specify do
          expect(parsed_response_body).to eq(
            {
              starts_at: "2024-12-22T10:00:00+02:00",
              duration_in_min: 30,
            }.deep_stringify_keys
          )
        end
      end

      response 404, "Renvoie un message d'erreur si aucun créneau n'est disponible" do
        run_test!
        schema type: :object, properties: { erreur: { type: :string } }, required: %w[erreur]

        let(:service) { "Gendarmerie" }

        specify do
          expect(parsed_response_body).to eq(
            {
              erreur: "Aucun créneau n'est disponible après cette date pour ce service.",
            }.deep_stringify_keys
          )
        end
      end
    end
  end
end
