# Ces feature specs sont complétées par des specs sur les cas que le formulaire ne permet pas de tester dans
# spec/requests/admin/territories/update_territory_admin_spec.rb

RSpec.describe "territory admin can manage access rights", type: :feature do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  context "when the current agent is territory admin" do
    let(:current_agent) { create(:agent, admin_in_territories: [territory]) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { login_as(current_agent, scope: :agent) }

    it "allows granting territory_admin to another agent" do
      create(:agent_territorial_access_right, agent: target_agent, territory: territory)

      visit edit_admin_territory_agent_path(territory, target_agent)

      check("Administrateur de #{territory.name_for_agent}")

      expect { click_on("Enregistrer les droits d'accès") }.to change { target_agent.reload.territorial_admin_in?(territory) }.to(true)
      expect(page).to have_content "Droits d'accès mis à jour"
    end

    it "allows revoking territory_admin from another admin, if not the last one" do
      create(:agent_territorial_access_right, :territory_admin, agent: target_agent, territory: territory)

      visit edit_admin_territory_agent_path(territory, target_agent)
      uncheck("Administrateur de #{territory.name_for_agent}")

      expect { click_on("Enregistrer les droits d'accès") }.to change { target_agent.reload.territorial_admin_in?(territory) }.to(false)
      expect(page).to have_content "Droits d'accès mis à jour"
    end
  end

  context "when the current agent is the last territory admin" do
    let(:solo_admin_organisation) { create(:organisation, territory: territory) }
    let(:solo_admin) { create(:agent, admin_role_in_organisations: [solo_admin_organisation], admin_in_territories: [territory]) }

    before { login_as(solo_admin, scope: :agent) }

    it "does not allow removing the last territory admin" do
      visit edit_admin_territory_agent_path(territory, solo_admin)
      uncheck("Administrateur de #{territory.name_for_agent}")
      click_on("Enregistrer les droits d'accès")

      expect(page).to have_content "Il doit toujours y avoir au moins un agent responsable par espace"
      expect(solo_admin.reload.territorial_admin_in?(territory)).to be true
    end
  end

  context "when the current agent only has allow_to_manage_access_rights" do
    let(:current_agent) { create(:agent) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before do
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)
      create(:agent_territorial_access_right, agent: target_agent, territory: territory)
      login_as(current_agent, scope: :agent)
    end

    it "allows editing the 3 specific rights of another agent" do
      visit edit_admin_territory_agent_path(territory, target_agent)

      check("Autorisé à créer, supprimer, modifier des équipes")
      check("Autorisé à inviter et affecter des agents sur des organisations")
      click_on("Enregistrer les droits d'accès")

      access_right = target_agent.reload.access_rights_for_territory(territory)
      expect(access_right.allow_to_manage_teams?).to be true
      expect(access_right.allow_to_invite_agents?).to be true
      expect(page).to have_content "Droits d'accès mis à jour"
    end
  end
end
