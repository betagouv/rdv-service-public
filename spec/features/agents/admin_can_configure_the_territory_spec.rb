RSpec.describe "Admin can configure the territory", type: :feature do
  context "with admin agent" do
    it "update territory phone number", type: :feature do
      territory = create(:territory, phone_number: nil)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory])
      login_as(agent, scope: :agent)

      visit edit_admin_territory_path(territory, agent)
      fill_in("Téléphone", with: "0101010101")
      click_on "Enregistrer"
      expect(territory.reload.phone_number).to eq("0101010101")
    end
  end

  context "with basic agent" do
    it "forbids from accessing the form", type: :feature do
      territory = create(:territory, phone_number: nil)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [])
      login_as(agent, scope: :agent)
      visit edit_admin_territory_path(territory, agent)
      expect(page).to have_content("Vous n’avez pas les droits suffisants")
    end
  end
end
