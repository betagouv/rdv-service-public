RSpec.describe "Creneaux", test_with_seed_data: true do
  subject(:get_request) do
    get "/api/visioplainte/creneaux", headers: auth_header, params: creneaux_params
    JSON.parse(response.body).deep_symbolize_keys
  end

  before(:all) do
    puts "Loading seeds"
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  around do |example|
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
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
end
