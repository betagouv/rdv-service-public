RSpec.describe "Visioplainte Creneaux" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  subject(:get_request) do
    get "/api/visioplainte/creneaux", headers: auth_header, params: creneaux_params
    response.parsed_body.deep_symbolize_keys
  end

  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
    create(:plage_ouverture,
           organisation: orga_gendarmerie,
           agent: Agent.find_by(last_name: "Guichet 1"),
           motifs: orga_gendarmerie.motifs,
           first_day: Date.tomorrow,
           start_time: Tod::TimeOfDay.new(14),
           end_time: Tod::TimeOfDay.new(18),
           recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday]))
  end

  let(:orga_gendarmerie) do
    Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie") # créée dans les seeds
  end

  include_context "Visioplainte Auth"

  context "when there are available créneaux" do
    let(:creneaux_params) do
      {
        service: "Gendarmerie",
        date_debut: "2024-08-19",
        date_fin: "2024-08-25",
      }
    end

    before do
      create(:plage_ouverture,
             organisation: orga_gendarmerie,
             agent: Agent.find_by(last_name: "Guichet 2"),
             motifs: orga_gendarmerie.motifs,
             first_day: Date.tomorrow,
             start_time: Tod::TimeOfDay.new(14),
             end_time: Tod::TimeOfDay.new(18),
             recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday]))
    end

    it "returns a list of creneaux without duplicates" do
      creneaux = get_request[:creneaux]
      expect(creneaux.first).to eq(
        {
          starts_at: "2024-08-19T14:00:00+02:00",
          duration_in_min: 30,
        }
      )

      creneaux_starting_at_2pm = creneaux.select do |c|
        c[:starts_at] == "2024-08-19T14:00:00+02:00"
      end

      expect(creneaux_starting_at_2pm.count).to eq 1
    end
  end

  describe "date de début et de fin" do
    let(:creneaux_params) do
      {
        service: "Gendarmerie",
        date_debut: "2024-08-19",
        date_fin: "2024-08-19",
      }
    end

    it "returns the creneaux included on the last day" do
      creneaux = get_request[:creneaux]
      expect(creneaux.count).to eq 8
      expect(creneaux.first[:starts_at]).to eq "2024-08-19T14:00:00+02:00"
      expect(creneaux.last[:starts_at]).to eq "2024-08-19T17:30:00+02:00"
    end

    context "when date_debut is missing" do
      let(:creneaux_params) do
        {
          service: "Gendarmerie",
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
          service: "Gendarmerie",
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
