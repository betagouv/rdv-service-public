# Ces feature specs sont complétées par des specs sur les permissions dans spec/controllers/admin/territories/agent_territorial_access_rights_controller_spec.rb

RSpec.describe "territory admin can list and invite agents", type: :feature do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "listing agents" do
    it "works" do
      zarg = create(:agent, last_name: "Zarg", admin_role_in_organisations: [organisation], admin_in_territories: [territory])
      blot = create(:agent, last_name: "Blot", basic_role_in_organisations: [organisation])
      create(:agent_territorial_access_right, agent: blot, territory: territory)
      login_as(zarg, scope: :agent)

      visit admin_territory_agents_path(territory_id: territory.id)
      expect(page).to have_content(zarg.email)
      expect(page).to have_content(blot.email)

      fill_in :q, with: "zarg"
      click_on "Rechercher"
      expect(page).to have_content(zarg.email)
      expect(page).not_to have_content(blot.email)

      fill_in :q, with: "autre"
      click_on "Rechercher"
      expect(page).not_to have_content(zarg.email)
      expect(page).not_to have_content(blot.email)
    end
  end

  describe "inviting an agent" do
    let(:admin) do
      create(:agent, admin_in_territories: [territory], admin_role_in_organisations: [organisation, other_organisation])
    end
    let!(:organisation) { create(:organisation, name: "MDS de Valence", territory: territory) }
    let!(:other_organisation) { create(:organisation, name: "MDS de Chambéry", territory: territory) }
    let!(:service) { create(:service, name: "Service Social", territories: [territory]) }

    before { login_as(admin, scope: :agent) }

    it "works" do
      visit new_admin_territory_agent_path(territory_id: territory.id)
      fill_in "Email", with: "agent@ladrome.fr"
      check "MDS de Valence"
      check "MDS de Chambéry"
      select "Service Social"
      click_on "Envoyer"

      expect(page).to have_content "L’agent agent@ladrome.fr a été invité à rejoindre votre organisation"

      expect(Agent.last).to have_attributes(
        email: "agent@ladrome.fr",
        organisations: [organisation, other_organisation],
        services: [service]
      )
      expect(AgentTerritorialAccessRight.last).to have_attributes(
        agent: Agent.last,
        territory: territory
      )
    end

    context "when trying to cheat and invite an agent to an organisation in another territory" do
      let!(:organisation_in_another_territory) { create(:organisation, territory: create(:territory)) }

      it "doesn't add the agent to the other organisation", js: true do
        visit new_admin_territory_agent_path(territory_id: territory.id)
        fill_in "Email", with: "agent@ladrome.fr"
        check "MDS de Valence"
        select "Service Social"

        # On modifie le html pour simuler une attaque
        page.execute_script("document.querySelector('input[value=\"#{organisation.id}\"]').value = #{organisation_in_another_territory.id}")
        click_on "Envoyer"

        expect(organisation_in_another_territory.agents).to be_empty
      end
    end
  end
end
