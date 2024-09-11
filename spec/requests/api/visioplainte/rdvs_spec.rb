RSpec.describe "Visioplainte Rdvs" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  include_context "Visioplainte Auth"
  let(:create_rdv) do
    post "/api/visioplainte/rdvs", headers: auth_header, params: create_rdv_params
    response.parsed_body.deep_symbolize_keys
  end

  let(:create_rdv_params) do
    {
      starts_at: "2024-08-19T08:00:00+02:00",
      service: "Police",
    }
  end

  describe "#create" do
    it "creates a rdv" do
      expect { create_rdv }.to change(Rdv, :count)

      created_rdv = Rdv.last

      expect(created_rdv).to have_attributes(
        created_by_type: "User",
        starts_at: Time.zone.parse("2024-08-19T08:00:00+02:00"),
        ends_at: Time.zone.parse("2024-08-19T08:30:00+02:00"),
        status: "unknown"
      )

      expect(created_rdv.motif.service.name).to eq "Police Nationale"
      expect(created_rdv.agents.first.full_name).to eq "GUICHET 1"
      expect(created_rdv.organisation.name).to eq "Plateforme Visioplainte Police"

      expect(created_rdv.users.first).to have_attributes(
        first_name: "Usager Anonyme",
        last_name: "Visioplainte"
      )
    end

    context "la configuration du motif a été modifiée par erreur et le rdv nécessite un lieu" do
      let(:service) { Service.find_by(name:  "Police Nationale") }
      let(:motif) { Motif.find_by(name: "Dépôt de plainte par visioconférence", service: service) }

      before do
        motif.update!(location_type: :public_office)
      end

      it "renders a 422 with validation erorrs" do
        response_hash = create_rdv
        expect(response.status).to eq 422
        expect(response_hash[:errors]).to eq(["Lieu doit être rempli(e)"])
      end
    end
  end

  describe "#cancel" do
    subject(:cancel_rdv) do
      put "/api/visioplainte/rdvs/#{rdv_id}/cancel", headers: auth_header
    end

    let(:rdv_id) do
      create_rdv[:id]
    end

    it "returns an ok status and makes the creneau available again" do
      cancel_rdv
      expect(response.status).to eq 200
      expect(response.parsed_body["status"]).to eq "excused"

      get "/api/visioplainte/creneaux/prochain", headers: auth_header, params: { service: "Police", date_debut: "2024-08-19" }
      expect(response.parsed_body["starts_at"]).to eq "2024-08-19T08:00:00+02:00"

      expect(Rdv.find(rdv_id).status).to eq "excused"
    end

    context "if trying to modify an rdv from another territory" do
      let(:other_rdv) { create(:rdv) }
      let(:rdv_id) { other_rdv.id }

      it "doesn't update the rdv and returns a 404 status" do
        cancel_rdv
        expect(response.status).to eq 404
        expect(other_rdv.reload.status).not_to eq "excused"
      end
    end
  end

  describe "#destroy" do
    subject(:destroy_rdv) do
      delete "/api/visioplainte/rdvs/#{rdv_id}", headers: auth_header
    end

    let(:rdv_id) { create_rdv[:id] }

    it "destroys the rdv makes the creneau available again" do
      destroy_rdv
      expect(response.status).to eq 204

      get "/api/visioplainte/creneaux/prochain", headers: auth_header, params: { service: "Police", date_debut: "2024-08-19" }
      expect(response.parsed_body["starts_at"]).to eq "2024-08-19T08:00:00+02:00"

      expect(Rdv.find_by(id: rdv_id)).to be_blank
    end

    context "if trying to modify an rdv from another territory" do
      let(:other_rdv) { create(:rdv) }
      let(:rdv_id) { other_rdv.id }

      it "doesn't update the rdv and returns a 404 status" do
        destroy_rdv
        expect(response.status).to eq 404
        expect(other_rdv.reload).to be_present
      end
    end
  end

  describe "#index" do
    subject(:get_index) do
      get "/api/visioplainte/rdvs/", headers: auth_header
    end

    before do
      create_rdv
    end

    it "returns the list of rdvs" do
      get_index
      expect(response.status).to eq 200

      expect(response.parsed_body["rdvs"][0]["starts_at"]).to eq "2024-08-19 08:00:00 +0200"
    end
  end
end
