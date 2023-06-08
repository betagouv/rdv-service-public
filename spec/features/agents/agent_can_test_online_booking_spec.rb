# frozen_string_literal: true

describe "Agents can try the user-facing online booking pages" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    motif = create(:motif, organisation: organisation, service: agent.service, bookable_publicly: true)
    motif.plage_ouvertures << create(:plage_ouverture, organisation: organisation, agent: agent)
  end

  it "shows the online booking forms, until the creneau selection" do
    login_as(agent, scope: :agent)
    visit public_link_to_org_path(organisation_id: organisation.id)
    expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
    click_link(agent.service.name)
    expect(page).to have_content("Sélectionnez un lieu de RDV :")
    click_link("Prochaine disponibilité")
    expect(page).to have_content("Sélectionnez un créneau :")
  end

  it "works on the RDV_MAIRIE domain" do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-mairie-test.localhost/#{public_link_to_org_path(organisation_id: organisation.id)}"
    expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
  end
end
