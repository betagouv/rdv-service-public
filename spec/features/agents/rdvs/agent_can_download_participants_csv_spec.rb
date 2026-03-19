RSpec.describe "agent can download a RDV's participants in CSV" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:user1) { create(:user, first_name: "Alice", last_name: "Martin", email: "alice@example.com", organisations: [organisation]) }
  let!(:user2) { create(:user, first_name: "Bob", last_name: "Dupont", email: "bob@example.com", organisations: [organisation]) }
  let!(:rdv) do
    create(:rdv, :collectif, organisation: organisation, agents: [agent], users: [user1, user2], starts_at: 3.days.from_now)
  end

  before { login_as(agent, scope: :agent) }

  it "shows the download link on the RDV page" do
    visit admin_organisation_rdv_path(organisation, rdv)
    expect(page).to have_link("Télécharger la liste des participants")
  end

  it "downloads a CSV with the participants' information" do
    visit admin_organisation_rdv_path(organisation, rdv)
    click_link "Télécharger la liste des participants"

    expect(response_headers["Content-Type"]).to include("text/csv")
    expected_filename = "participants-rdv-collectif-#{rdv.starts_at.to_date}.csv"
    expect(response_headers["Content-Disposition"]).to include(expected_filename)

    expected_csv = <<~CSV
      full_name,email,status
      Alice MARTIN,alice@example.com,Rendez-vous à venir
      Bob DUPONT,bob@example.com,Rendez-vous à venir
    CSV
    expect(page.body).to eq(expected_csv)
  end

  context "when a participation has a non-default status" do
    before { rdv.participations.find_by!(user: user1).update!(status: "seen") }

    it "reflects the correct status for each participant" do
      visit download_participants_admin_organisation_rdv_path(organisation, rdv)

      expected_csv = <<~CSV
        full_name,email,status
        Alice MARTIN,alice@example.com,Rendez-vous honoré
        Bob DUPONT,bob@example.com,Rendez-vous à venir
      CSV
      expect(page.body).to eq(expected_csv)
    end
  end
end
