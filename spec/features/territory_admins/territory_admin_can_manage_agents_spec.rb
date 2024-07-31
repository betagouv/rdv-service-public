RSpec.describe "territory admin can manage agents", type: :feature do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "listing agents" do
    it "works" do
      zarg = create(:agent, last_name: "Zarg", admin_role_in_organisations: [organisation], role_in_territories: [territory])
      create(:agent_territorial_access_right, agent: zarg, territory: territory)
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
    let(:admin) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }
    let!(:organisation) { create(:organisation, name: "MDS de Valence", territory: territory) }
    let!(:service) { create(:service, name: "Service Social", territories: [territory]) }

    before { login_as(admin, scope: :agent) }

    it "works" do
      visit new_admin_territory_agent_path(territory_id: territory.id)
      fill_in "Email", with: "agent@ladrome.fr"
      check "MDS de Valence"
      # TODO: essayer d'ajouter à deux organisations
      select "Service Social"
      click_on "Envoyer"

      expect(page).to have_content "L’agent agent@ladrome.fr a été invité à rejoindre votre organisation"

      expect(Agent.last).to have_attributes(
        email: "agent@ladrome.fr",
        organisations: [organisation],
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

  describe "removing an agent from a team" do
    it "works" do
      team_a = create(:team, name: "A", territory: territory)
      team_b = create(:team, name: "B", territory: territory)
      current_agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [team_a])
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [team_a, team_b])
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
      login_as(current_agent, scope: :agent)

      visit edit_admin_territory_agent_path(territory_id: territory.id, id: agent.id)
      unselect team_a.name, from: "Équipes"
      expect { click_on "Enregistrer" }.to change { agent.reload.teams }.to([team_b])
    end
  end

  describe "changing agent service" do
    let(:service_a) { create(:service, name: "A", territories: [territory]) }
    let(:service_b) { create(:service, name: "B", territories: [territory]) }
    let(:service_c) { create(:service, name: "C", territories: [territory]) }
    let!(:edited_agent) { create(:agent, admin_role_in_organisations: [organisation], services: [service_a, service_b]) }

    before do
      current_agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], services: [service_c])
      # l'agent qui édite doit avoir les droits d'édition
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)
      # l'agent édité doit avoir un agent_territorial_access_right car sinon le formulaire plante
      create(:agent_territorial_access_right, agent: edited_agent, territory: territory)

      login_as(current_agent, scope: :agent)
      visit edit_admin_territory_agent_path(territory_id: territory.id, id: edited_agent.id)
    end

    it "allows adding and removing services" do
      select service_c.name, from: "Services"
      unselect service_b.name, from: "Services"
      expect { click_on "Enregistrer les services" }.to change { edited_agent.reload.services.to_set }
        .from([service_a, service_b].to_set)
        .to([service_a, service_c].to_set)
    end

    it "forbids removing a service that still have plages" do
      create(:plage_ouverture, agent: edited_agent, motifs: [create(:motif, service: service_b)])
      unselect service_b.name, from: "Services"
      expect { click_on "Enregistrer les services" }.not_to change { edited_agent.reload.services.to_set }
      expect(page).to have_content("Le retrait du service n'a pu aboutir car l'agent a toujours des plages d'ouverture actives sur le service : B")
    end

    it "forbids removing last service" do
      unselect service_a.name, from: "Services"
      unselect service_b.name, from: "Services"
      expect { click_on "Enregistrer les services" }.not_to change { edited_agent.reload.services.to_set }
      expect(page).to have_content("Un agent doit avoir au moins un service")
    end
  end
end
