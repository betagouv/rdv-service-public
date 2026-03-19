RSpec.describe "agent can download a RDV's participants in CSV" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:rdv) { create(:rdv, :collectif, organisation: organisation, agents: [agent], starts_at: 3.days.from_now) }

  before { login_as(agent, scope: :agent) }

  it "shows the download link on the RDV page" do
    visit admin_organisation_rdv_path(organisation, rdv)
    expect(page).to have_link("Télécharger la liste des participants")
  end

  it "downloads the CSV produced by ParticipantsCsv" do
    generator = instance_double(ParticipantsCsv, generate_csv: "full_name,email,status\n", filename: "participants-rdv-collectif-2025-06-15.csv")
    allow(ParticipantsCsv).to receive(:new).with(rdv).and_return(generator)

    visit download_participants_admin_organisation_rdv_path(organisation, rdv)

    expect(response_headers["Content-Type"]).to include("text/csv")
    expect(response_headers["Content-Disposition"]).to include("participants-rdv-collectif-2025-06-15.csv")
    expect(page.body).to eq("full_name,email,status\n")
  end
end
