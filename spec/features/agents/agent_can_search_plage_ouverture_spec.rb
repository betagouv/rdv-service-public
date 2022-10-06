# frozen_string_literal: true

describe "Agent can search plage ouverture" do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, organisations: [organisation]) }
  let!(:perm_enfance) { create(:plage_ouverture, title: "Permanence Enfance en cours", agent: agent, organisation: organisation) }
  let!(:perm_scolaire) { create(:plage_ouverture, title: "Permanence Scolaire en cours", agent: agent, organisation: organisation) }
  let!(:expired_perm_enfance) { create(:plage_ouverture, :expired, title: "Permanence Enfance passée", agent: agent, organisation: organisation) }
  let!(:expired_perm_scolaire) { create(:plage_ouverture, :expired, title: "Permanence Scolaire passée", agent: agent, organisation: organisation) }

  before do
    login_as(agent, scope: :agent)
    visit admin_organisation_agent_plage_ouvertures_path(organisation, agent)
  end

  it "displays the correct elements before search" do
    expect(find_link("En cours")[:class]).to include("active")
    expect(find_link("Passées")[:class]).not_to include("active")
    expect(page).to have_content(perm_enfance.title).once
    expect(page).to have_content(perm_scolaire.title).once
    expect(page).not_to have_content(expired_perm_enfance.title)
    expect(page).not_to have_content(expired_perm_scolaire.title)
  end

  it "displays the correct elements after search" do
    fill_in :search, with: "sco"
    click_button "Rechercher"

    expect(page).not_to have_content(perm_enfance.title)
    expect(page).to have_content(perm_scolaire.title).once
    expect(page).not_to have_content(expired_perm_enfance.title)
    expect(page).not_to have_content(expired_perm_scolaire.title)
  end

  it "preserves the search after tab changes" do
    fill_in :search, with: "sco"
    click_button "Rechercher"
    click_link("Passées")

    expect(find_link("En cours")[:class]).not_to include("active")
    expect(find_link("Passées")[:class]).to include("active")
    expect(page).not_to have_content(perm_enfance.title)
    expect(page).not_to have_content(perm_scolaire.title)
    expect(page).not_to have_content(expired_perm_enfance.title)
    expect(page).to have_content(expired_perm_scolaire.title).once
  end
end
