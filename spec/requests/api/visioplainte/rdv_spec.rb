RSpec.describe "Visioplainte Rdvs" do
  subject(:create_rdv) do
    post "/api/visioplainte/rdvs", headers: auth_header, params: rdv_params
    JSON.parse(response.body).deep_symbolize_keys
  end

  include_context "Visioplainte"

  let(:rdv_params) do
    {
      starts_at: "2024-08-19T08:00:00+02:00",
      service: "Police",
    }
  end

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
