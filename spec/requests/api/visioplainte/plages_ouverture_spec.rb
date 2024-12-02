RSpec.describe "Visioplainte Plages d'ouverture" do
  before do
    travel_to Time.zone.local(2024, 8, 19, 8, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  include_context "Visioplainte Auth"
  let(:agent) do
    Agent.joins(:services).where(services: { name: "Gendarmerie Nationale" }).last
  end

  describe "general case" do
    let!(:plage_ouverture_without_recurrence) do
      create(:plage_ouverture, :no_recurrence, agent: agent, first_day: Date.new(2024, 8, 19), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end
    let!(:plage_ouverture_with_recurrence) do
      create(:plage_ouverture, :weekdays, agent: agent, first_day: Date.new(2024, 8, 1), start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(18))
    end

    it "returns the list of occurrences of the plage ouverture for visioplainte" do
      get "/api/visioplainte/plages_ouverture", params: { date_debut: "2024-08-19", date_fin: "2024-08-25" }, headers: auth_header
      expect(response.status).to eq 200

      expect(response.parsed_body["plages_ouverture"][0]).to eq(
        {
          id: plage_ouverture_without_recurrence.id,
          starts_at: "2024-08-19T09:00:00+02:00",
          ends_at: "2024-08-19T12:00:00+02:00",
          guichet_id: agent.id,
        }.stringify_keys
      )

      expect(response.parsed_body["plages_ouverture"][1]).to eq(
        {
          id: plage_ouverture_with_recurrence.id,
          starts_at: "2024-08-19T14:00:00+02:00",
          ends_at: "2024-08-19T18:00:00+02:00",
          guichet_id: agent.id,
        }.stringify_keys
      )
    end
  end

  describe "filtering by guichet" do
    let(:agent1) do
      Agent.joins(:services).where(services: { name: "Gendarmerie Nationale" }).find_by(last_name: "Guichet 1")
    end
    let(:agent2) do
      Agent.joins(:services).where(services: { name: "Gendarmerie Nationale" }).find_by(last_name: "Guichet 2")
    end
    let!(:plage_ouverture1) do
      create(:plage_ouverture, :no_recurrence, agent: agent1, first_day: Date.new(2024, 8, 19), start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
    end
    let!(:plage_ouverture2) do
      create(:plage_ouverture, :no_recurrence, agent: agent2, first_day: Date.new(2024, 8, 19), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end

    it "returns plage ouverture for the correct guichet" do
      get "/api/visioplainte/plages_ouverture", params: { date_debut: "2024-08-19", date_fin: "2024-08-25", guichet_ids: [agent1.id] }, headers: auth_header
      plages_ouvertures = response.parsed_body["plages_ouverture"]
      expect(plages_ouvertures.count).to eq(1)
      expect(plages_ouvertures.first["starts_at"]).to eq("2024-08-19T08:00:00+02:00")
    end
  end

  context "without required params" do
    it "returns an error" do
      get "/api/visioplainte/plages_ouverture", params: { date_debut: "2024-08-19", date_fin: nil }, headers: auth_header
      expect(response.status).to eq 400
      expect(response.parsed_body["errors"].first).to eq "Vous devez préciser les paramètres date_debut et date_fin"
    end
  end
end
