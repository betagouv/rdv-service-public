RSpec.describe "Un agent admin peut filtrer la liste d'agents" do
  let(:organisation) { create(:organisation) }
  let(:admin) { create(:agent, first_name: "Raoul", last_name: "Jean", admin_role_in_organisations: [organisation]) }
  let!(:tony) { create(:agent, first_name: "Tony", last_name: "Hamaz", basic_role_in_organisations: [organisation]) }
  let!(:other_admin) { create(:agent, first_name: "Ada", last_name: "Jean", admin_role_in_organisations: [organisation]) }
  let!(:other_agent1) { create(:agent, first_name: "Emilia", last_name: "Cori", basic_role_in_organisations: [organisation]) }
  let!(:other_agent2) { create(:agent, first_name: "Johana", last_name: "Dupont", basic_role_in_organisations: [organisation]) }
  let!(:other_agent3) { create(:agent, first_name: "Filipo", last_name: "Carozzo", basic_role_in_organisations: [organisation]) }

  specify "recherche textuelle" do
    login_as(admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    %w[Raoul Tony Ada Emilia Johana Filipo].each { expect(page).to have_content(_1) }
    expect(page).to have_field(placeholder: "Prénom, Nom, Email")
    fill_in placeholder: "Prénom, Nom, Email", with: "Jean"
    click_button "Rechercher"
    expect(page).to have_content("Raoul")
    expect(page).to have_content("Ada")
    expect(page).not_to have_content("Tony")
    expect(page).not_to have_content("Emilia")
    expect(page).not_to have_content("Johana")
    expect(page).not_to have_content("Filipo")
    expect(page).to have_content("2 agents correspondent à vos filtres")

    click_link "Réinitialiser les filtres"
    %w[Raoul Tony Ada Emilia Johana Filipo].each { expect(page).to have_content(_1) }
  end

  specify "filtre admin seulement" do
    login_as(admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    choose "Admins uniquement"
    click_button "Rechercher"

    expect(page).to have_content("Ada")
    expect(page).to have_no_content("Tony")
    expect(page).not_to have_content("Emilia")
    expect(page).not_to have_content("Johana")
    expect(page).not_to have_content("Filipo")
  end

  specify "le contrôle segmenté applique le filtre immédiatement", js: true do
    login_as(admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    find("label", text: "Admins uniquement").click

    expect(page).to have_content("Ada")
    expect(page).to have_no_content("Tony")
  end
end
