RSpec.describe "territory admin can manage agents", type: :feature do
  # Le territoire doit avoir au moins un agent admin de territoire restant
  let!(:territory) { create(:territory, :mairies).tap { |t| t.roles.create!(agent: create(:agent)) } }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }
  let!(:service_a) { create(:service) }
  let!(:service_b) { create(:service) }
  let!(:service_c) { create(:service) }

  before do
    create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent)
    create(:agent_role, agent: agent, access_level: "basic")
    login_as(agent, scope: :agent)
  end

  describe "Listing services" do
    it "works" do
      visit edit_admin_territory_services_path(territory)

      expect(page).to have_content("Vous pouvez activer ou désactiver les services auxquels vos agents peuvent être affectés.")
      expect(page).to have_content(service_a.name)
      expect(page).to have_content(service_b.name)
      expect(page).to have_content(service_c.name)
    end
  end

  describe "Activating/Deactivating services" do
    it "works" do
      visit edit_admin_territory_services_path(territory)
      check service_a.name
      check service_b.name

      expect { click_on "Enregistrer" }.to change {
        territory.reload.services.ids
      }.from([]).to([service_a.id, service_b.id])
      expect(page).to have_content("Liste des services disponibles mise à jour")

      uncheck service_b.name
      check service_c.name

      expect { click_on "Enregistrer" }.to change {
        territory.reload.services.ids
      }.from([service_a.id, service_b.id]).to([service_a.id, service_c.id])
      expect(page).to have_content("Liste des services disponibles mise à jour")
    end
  end
end
