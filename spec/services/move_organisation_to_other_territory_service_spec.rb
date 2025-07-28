require "rails_helper"

RSpec.describe MoveOrganisationToOtherTerritoryService do
  subject { described_class.new(origin_organisation: organisation, target_territory: territory_target) }

  let!(:territory_origin) { create(:territory, name: "Territoire d'origine") }
  let!(:territory_target) { create(:territory, name: "Territoire cible") }
  let!(:organisation) { create(:organisation, territory: territory_origin) }

  context "cas simple" do
    it "déplace l'organisation vers le territoire cible" do
      expect { subject.call }.to change { organisation.reload.territory }.from(territory_origin).to(territory_target)
    end
  end

  describe "gestion des annotations" do
    let!(:user1) { create(:user, organisations: [organisation]) }
    let!(:annotation1_origin) { create(:annotation, user: user1, territory: territory_origin, content: "Usager très sympa") }
    let!(:user2) { create(:user, organisations: [organisation]) }
    let!(:annotation2_origin) { create(:annotation, user: user2, territory: territory_origin, content: "Super") }
    let!(:annotation2_target) { create(:annotation, user: user2, territory: territory_target, content: "Réjouissant") }

    specify do
      subject.call
      expect(annotation1_origin.reload.territory).to eq(territory_target)
      expect(annotation2_target.reload.content).to eq("Réjouissant\n---\nSuper")
      expect(Annotation.find_by(id: annotation2_origin.id)).to be_nil
    end
  end

  describe "gestion des catégories de motifs" do
    let!(:motif_categories_origin) { create_list(:motif_category, 3, territories: [territory_origin]) }
    let!(:motif_category_both) { create(:motif_category, name: "Catégorie 2", territories: [territory_origin, territory_target]) }
    let!(:motif_category_target) { create(:motif_category, name: "Catégorie 3", territories: [territory_target]) }
    let!(:motif_category_other_territory) { create(:motif_category, name: "Catégorie 4", territories: [create(:territory)]) }

    specify do
      subject.call
      motif_categories_origin.each do |motif_category|
        expect(motif_category.reload.territories).to include(territory_origin, territory_target)
      end
      expect(motif_category_both.reload.territories).to include(territory_origin, territory_target)
      expect(motif_category_target.reload.territories).to include(territory_target)
      expect(motif_category_target.reload.territories).not_to include(territory_origin)
      expect(motif_category_other_territory.reload.territories).not_to include(territory_origin)
      expect(motif_category_other_territory.reload.territories).not_to include(territory_target)
    end
  end

  describe "gestion des services" do
    let!(:service_pmi) { create(:service, name: "PMI") }
    let!(:territory_service_pmi) { create(:territory_service, territory: territory_origin, service: service_pmi) }
    let!(:service_justice) { create(:service, name: "Justice") }
    let!(:territory_service_justice1) { create(:territory_service, service: service_justice, territory: territory_origin) }
    let!(:territory_service_justice2) { create(:territory_service, service: service_justice, territory: territory_target) }
    let!(:service_aide) { create(:service, name: "Aide") }
    let!(:territory_service_aide) { create(:territory_service, service: service_aide, territory: territory_target) }

    specify do
      subject.call
      expect(territory_target.reload.services).to include(service_pmi)
      expect(territory_target.reload.services).to include(service_justice)
      expect(territory_target.reload.services).to include(service_aide)
    end
  end

  context "gestion des équipes" do
    # une équipe à créer + une équipe à fusionner
    let!(:organisation_target) { create(:organisation, territory: territory_target) }
    let!(:agent_origin1) { create(:agent, organisations: [organisation]) }
    let!(:agent_target1) { create(:agent, organisations: [organisation_target]) }
    let!(:team_habilites_origin) { create(:team, name: "Agents habilités", territory: territory_origin) }
    let!(:team_visiteurices_origin) { create(:team, name: "Visiteur·ices", territory: territory_origin) }
    let!(:team_visteurices_target) { create(:team, name: "Visiteur·ices", territory: territory_target) }

    before do
      team_habilites_origin.agents << agent_origin1
      team_visiteurices_origin.agents << agent_origin1
      team_visteurices_target.agents << agent_target1
    end

    specify do
      subject.call
      expect(territory_target.teams.find_by(name: "Agents habilités")).to be_present
      expect(agent_origin1.reload.teams.where(territory: territory_target).map(&:name)).to contain_exactly("Agents habilités", "Visiteur·ices")
      expect(team_visteurices_target.agents).to contain_exactly(agent_origin1, agent_target1)
      expect(territory_origin.teams).to be_empty
    end
  end

  context "gestion des droits d'accès" do
    let!(:agent_lea) { create(:agent, organisations: [organisation]) }
    let!(:agent_jean) { create(:agent, organisations: [organisation]) }

    before do
      create(:agent_territorial_access_right, agent: agent_lea, territory: territory_origin, allow_to_manage_teams: true)
      create(:agent_territorial_access_right, agent: agent_jean, territory: territory_origin, allow_to_manage_teams: true)
      create(:agent_territorial_access_right, agent: agent_jean, territory: territory_target, allow_to_invite_agents: true)
    end

    specify do
      subject.call
      agent_lea.reload
      expect(agent_lea.agent_territorial_access_rights.where(territory: territory_origin)).to be_empty
      expect(agent_lea.agent_territorial_access_rights.where(territory: territory_target).count).to eq 1
      expect(agent_lea.agent_territorial_access_rights.find_by(territory: territory_target).allow_to_manage_teams).to be true
      # jean a un rôle dans les 2 territoires, son nouvel accès combine les droits positifs dans les deux
      agent_jean.reload
      expect(agent_jean.agent_territorial_access_rights.where(territory: territory_origin)).to be_empty
      expect(agent_jean.agent_territorial_access_rights.where(territory: territory_target).count).to eq 1
      expect(agent_jean.agent_territorial_access_rights.find_by(territory: territory_target).allow_to_manage_teams).to be true
      expect(agent_jean.agent_territorial_access_rights.find_by(territory: territory_target).allow_to_invite_agents).to be true
    end
  end

  context "gestion des rôles territoriaux" do
    let!(:agent1) { create(:agent, organisations: [organisation]) }
    let!(:agent2) { create(:agent, organisations: [organisation]) }

    before do
      create(:agent_territorial_role, agent: agent1, territory: territory_origin)
      create(:agent_territorial_role, agent: agent2, territory: territory_origin)
      create(:agent_territorial_role, agent: agent2, territory: territory_target)
    end

    specify do
      subject.call
      expect(agent1.territorial_roles.where(territory: territory_origin)).to be_empty
      expect(agent1.territorial_roles.where(territory: territory_target)).to be_present
      expect(agent2.territorial_roles.where(territory: territory_target)).to be_present
    end
  end

  context "gestion des secteurs" do
    let!(:sectors) { create_list(:sector, 2, territory: territory_origin) }
    let!(:attributions) { create(:sector_attribution, organisation: organisation, sector: sectors[0]) }

    specify do
      subject.call
      expect(Sector.where(territory: territory_origin)).to be_empty
      expect(SectorAttribution.where(organisation:)).to be_empty
    end
  end
end
