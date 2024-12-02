RSpec.describe "Agents can try the user-facing online booking pages" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    first_day = Date.parse("2023/08/01")
    travel_to(first_day.beginning_of_day)
    motif = create(:motif, organisation: organisation, service: agent.services.first, name: "Accompagnement Formation")
    motif.plage_ouvertures << create(:plage_ouverture, first_day: first_day, organisation: organisation, agent: agent)
  end

  it "shows the online booking forms, until the creneau selection" do
    login_as(agent, scope: :agent)
    visit public_link_to_org_path(organisation_id: organisation.id)
    expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
    click_link(agent.services.first.name)
    expect(page).to have_content("Sélectionnez le motif de votre RDV :")
    click_link("Accompagnement Formation")
    expect(page).to have_content("Sélectionnez un lieu de RDV")
    click_link("Prochaine disponibilité")
    expect(page).to have_content("Sélectionnez un créneau")
  end

  it "works on the RDV_MAIRIE domain" do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-mairie-test.localhost/#{public_link_to_org_path(organisation_id: organisation.id)}"
    expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
  end
end
