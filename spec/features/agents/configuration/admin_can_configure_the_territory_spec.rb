RSpec.describe "Admin can configure the territory" do
  context "with admin agent" do
    it "update territory phone number" do
      territory = create(:territory, name: "Ville de Montreuil")
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory])
      login_as(agent, scope: :agent)

      visit edit_admin_territory_path(territory)
      fill_in("Nom", with: "Commune de Montreuil")
      click_on "Enregistrer"
      expect(territory.reload.name).to eq("Commune de Montreuil")
    end
  end

  context "with basic agent" do
    it "forbids from accessing the form" do
      territory = create(:territory, name: "Ville de Montreuil")
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [])
      login_as(agent, scope: :agent)
      visit edit_admin_territory_path(territory)
      expect(page).to have_content("Vous n’avez pas les droits suffisants")
    end
  end
end
