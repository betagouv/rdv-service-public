RSpec.describe "Visioplainte Rdvs" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
    PlageOuverture.create!(
      title: "Permanence classique",
      organisation: Organisation.last,
      agent: Agent.find_by(last_name: "Guichet 1"),
      motifs: [Motif.last],
      first_day: Date.tomorrow,
      start_time: Tod::TimeOfDay.new(8),
      end_time: Tod::TimeOfDay.new(12),
      recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
    )
  end

  include_context "Visioplainte Auth"
  let(:create_rdv) do
    post "/api/visioplainte/rdvs", headers: auth_header, params: create_rdv_params
    response.parsed_body.deep_symbolize_keys
  end

  let(:create_rdv_params) do
    {
      starts_at: "2024-08-19T08:00:00+02:00",
      service: "Gendarmerie",
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

      expect(created_rdv.motif.service.name).to eq "Gendarmerie Nationale"
      expect(created_rdv.agents.first.full_name).to eq "GUICHET 1"
      expect(created_rdv.organisation.name).to eq "Plateforme Visioplainte Gendarmerie"

      expect(created_rdv.users.first).to have_attributes(
        first_name: "Usager Anonyme",
        last_name: "Visioplainte"
      )
    end

    context "la configuration du motif a été modifiée par erreur et le rdv nécessite un lieu" do
      let(:service) { Service.find_by(name:  "Gendarmerie Nationale") }
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

      get "/api/visioplainte/creneaux/prochain", headers: auth_header, params: { service: "Gendarmerie", date_debut: "2024-08-19" }
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

      get "/api/visioplainte/creneaux/prochain", headers: auth_header, params: { service: "Gendarmerie", date_debut: "2024-08-19" }
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
    before { create_rdv }

    it "returns the list of rdvs" do
      get "/api/visioplainte/rdvs/", params: { date_debut: "2024-08-19T08:00:00+02:00", date_fin: "2024-08-20T08:00:00+02:00" }, headers: auth_header
      expect(response.status).to eq 200

      expect(response.parsed_body["rdvs"][0]["starts_at"]).to eq "2024-08-19 08:00:00 +0200"
    end

    describe "authentication" do
      it "returns a 400 status if the auth header is missing" do
        get "/api/visioplainte/rdvs/", params: { date_debut: "2024-08-19T08:00:00+02:00", date_fin: "2024-08-20T08:00:00+02:00" }, headers: {}
        expect(response.status).to eq 401
        expect(response.parsed_body["rdvs"]).to be_blank
      end
    end

    context "when there are no rdvs for the date_debut and date_fin params" do
      it "returns an empty list" do
        get "/api/visioplainte/rdvs/", params: { date_debut: "2024-08-22T08:00:00+02:00", date_fin: "2024-08-23T08:00:00+02:00" }, headers: auth_header
        expect(response.status).to eq 200

        expect(response.parsed_body["rdvs"]).to be_empty
      end
    end

    context "when asking for specific rdv ids" do
      it "returns the rdvs" do
        get "/api/visioplainte/rdvs/", params: { ids: [Rdv.last.id] }, headers: auth_header
        expect(response.status).to eq 200

        expect(response.parsed_body["rdvs"][0]["id"]).to eq Rdv.last.id
      end

      it "doesn't allow getting a rdv that belongs to another territory" do
        rdv = create(:rdv)
        get "/api/visioplainte/rdvs/", params: { ids: [rdv.id] }, headers: auth_header

        expect(response.parsed_body["rdvs"]).to be_empty
      end
    end

    context "when filtering by guichet" do
      let(:date_params) do
        { date_debut: "2024-08-19T08:00:00+02:00", date_fin: "2024-08-20T08:00:00+02:00" }
      end

      let(:gendarmerie_guichet_ids) do
        Agent.joins(:services).where(services: { name: ["Gendarmerie Nationale"] }).pluck(:id)
      end

      it "returns only the rdvs of the given guichets" do
        # Le rdv créé est pour le guichet 1, donc un appel sur le guichet 2 renvoie une liste vide
        get "/api/visioplainte/rdvs/", params: { guichet_ids: Agent.where(last_name: "Guichet 2").pluck(:id) }.merge(date_params), headers: auth_header

        expect(response.parsed_body["rdvs"]).to be_empty

        get "/api/visioplainte/rdvs/", params: { guichet_ids: Agent.where(last_name: "Guichet 1").pluck(:id) }.merge(date_params), headers: auth_header
        expect(response.parsed_body["rdvs"][0]["id"]).to eq Rdv.last.id
      end
    end

    context "without date_debut, date_fin or ids params" do
      it "returns an error" do
        get "/api/visioplainte/rdvs/", params: {}, headers: auth_header

        expect(response.status).to eq 400
        expect(response.parsed_body["errors"].first).to eq "Vous devez préciser le paramètre ids ou les paramètres date_debut et date_fin"
      end
    end
  end
end
