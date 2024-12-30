RSpec.describe "Agent can cancel a RDV", js: true do
  let(:rdv) { create(:rdv) }
  let(:agent) { rdv.agents.first }

  before do
    rdv.participations.first.update!(send_lifecycle_notifications: false)
    stub_netsize_ok
    login_as(agent, scope: :agent)
  end

  it "n'envoie pas de notification si la participation a désactivé les notifications" do
    visit admin_organisation_rdv_path(rdv.organisation, rdv)
    find(".dropdown-toggle", text: "Rendez-vous à venir").click
    accept_alert do
      find("span", text: "Annulé à l’initiative du service").click
    end
    sleep 1 # Pour attendre que la requête ajax se finisse
    expect(rdv.reload.status).to eq("revoked")

    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.map(&:to)).to be_empty
    expect(Receipt.all).to be_empty
  end
end
