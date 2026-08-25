# Ces feature specs sont complétées par des specs sur les permissions dans spec/controllers/admin/territories/agent_territorial_access_rights_controller_spec.rb

RSpec.describe "territory admin can manage access rights", type: :feature do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "setting access rights" do
    let(:current_agent) { create(:agent) }

    it "allows modifying them" do
      login_as(current_agent, scope: :agent)
      create(:agent_territorial_access_right, :territory_admin, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)

      agent = create(:agent, basic_role_in_organisations: [organisation])
      create(:agent_territorial_access_right, agent: agent, territory: territory)

      visit edit_admin_territory_agent_path(territory_id: territory.id, id: agent.id)
      check "Autorisé à créer, supprimer, modifier des équipes"

      click_on "Enregistrer les droits d'accès", match: :first
      expect(page).to have_content "Droits d'accès mis à jour"
    end
  end
end
