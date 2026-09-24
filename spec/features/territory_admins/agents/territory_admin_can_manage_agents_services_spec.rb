# Ces feature specs sont complétées par des specs sur les permissions dans spec/controllers/admin/territories/agent_territorial_access_rights_controller_spec.rb

RSpec.describe "territory admin can manage agents services", type: :feature do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "changing agent service" do
    let(:service_a) { create(:service, name: "Service A", territories: [territory]) }
    let(:service_b) { create(:service, name: "Service B", territories: [territory]) }
    let(:service_c) { create(:service, name: "Service C", territories: [territory]) }
    let!(:edited_agent) { create(:agent, admin_role_in_organisations: [organisation], services: [service_a, service_b]) }

    before do
      current_agent = create(:agent, admin_role_in_organisations: [organisation], services: [service_c])
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
      expect(page).to have_content("Le retrait du service n'a pu aboutir car l'agent a toujours des plages d'ouverture actives sur le service : Service B")
    end
  end

  describe "un agent appartient à un service désactivé" do
    let!(:service_a) { create(:service, name: "Service A", territories: [territory]) }
    let!(:service_b) { create(:service, name: "Service B") }
    let!(:edited_agent) { create(:agent, admin_role_in_organisations: [organisation], services: [service_b]) }

    before do
      current_agent = create(:agent, admin_role_in_organisations: [organisation], services: [service_a])
      # l'agent qui édite doit avoir les droits d'édition
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)
      # l'agent édité doit avoir un agent_territorial_access_right car sinon le formulaire plante
      create(:agent_territorial_access_right, agent: edited_agent, territory: territory)

      login_as(current_agent, scope: :agent)
      visit edit_admin_territory_agent_path(territory_id: territory.id, id: edited_agent.id)
    end

    it "permet de supprimer le service désactivé de l’agent et le réaffecter à un autre" do
      unselect "Service B (désactivé dans l'espace courant)", from: "Services"
      select "Service A", from: "Services"
      expect { click_on "Enregistrer les services" }.to change { edited_agent.reload.services.to_set }
        .from([service_b])
        .to([service_a])
    end
  end
end
