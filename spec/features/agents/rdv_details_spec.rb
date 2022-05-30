# frozen_string_literal: true

describe "Agent can see RDV details", js: true do
  before do
    travel_to(Time.zone.local(2022, 4, 4))
    login_as(agent, scope: :agent)
  end

  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }
  let(:motif) { create(:motif, service: service, name: "Renseignements") }
  let!(:rdv) { create(:rdv, agents: [agent], motif: motif, organisation: organisation, starts_at: starts_at) }
  let(:starts_at) { Time.zone.local(2022, 4, 7).at_noon }
  let!(:receipt) { create(:receipt, rdv: rdv, result: :sent, content: "Vous avez rendez-vous!") }
  let(:agent) { create(:agent, first_name: "Bruce", last_name: "Wayne", service: service, basic_role_in_organisations: [organisation]) }

  it "allows listing RDVs" do
    visit admin_organisation_rdvs_path(organisation)

    expect(page).to have_text("Liste des RDV")
    click_link("Le jeudi 07 avril 2022")
    expect(page).to have_text("Renseignements")
    expect(page).to have_text("Bruce WAYNE")

    click_button("Notifications envoyées")
    expect(page).to have_text("Contenu")
    expect(page).to have_text("Vous avez rendez-vous!")
  end

  context "when the rdv is over" do
    let(:starts_at) { 1.day.ago }

    it "allows editing the RDV status", js: true do
      visit admin_organisation_rdv_path(organisation, rdv.id)
      find(".btn", text: "À renseigner").click
      expect do
        find("span", text: "Rendez-vous honoré").click
      end.to change { rdv.reload.status }.to("seen")
    end
  end
end
