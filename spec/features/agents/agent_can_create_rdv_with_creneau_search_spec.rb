# frozen_string_literal: true

describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
  let!(:agent2) { create(:agent, first_name: "Robert", last_name: "Voila", service: service, basic_role_in_organisations: [organisation]) }
  let!(:agent3) { create(:agent, first_name: "Michel", last_name: "Lapin", service: service, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, reservable_online: true, service: service, organisation: organisation) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu2, agent: agent2, organisation: organisation) }
  let!(:plage_ouverture3) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent3, organisation: organisation) }

  before do
    travel_to(Time.zone.local(2019, 7, 22))
    login_as(agent, scope: :agent)
    visit admin_organisation_agent_searches_path(organisation)
  end

  it "default", js: true do
    expect(page).to have_content("Trouver un créneau")
    select(motif.name, from: "motif_id")
    click_button("Afficher les créneaux")

    # Display results for both lieux
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).to have_content(plage_ouverture2.lieu.address)

    # Add a filter on lieu
    select(lieu.name, from: "lieu_ids")
    click_button("Afficher les créneaux")
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).not_to have_content(plage_ouverture2.lieu.address)

    # TODO : refaire un parcours jusqu'à l'enregistrement du RDV
  end
end
