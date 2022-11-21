# frozen_string_literal: true

describe "Agent can list RDVs" do
  let!(:organisation) { create(:organisation) }
  let!(:current_agent) { create(:agent, organisations: [organisation]) }

  before do
    login_as(current_agent, scope: :agent)
  end

  describe "RDV visibility within organisation" do
    let!(:agent_from_same_service) { create(:agent, organisations: [organisation], service: current_agent.service) }
    let!(:agent_from_other_service) { create(:agent, organisations: [organisation]) }

    before do
      [current_agent, agent_from_same_service, agent_from_other_service].each do |agent|
        create(:rdv, organisation: organisation, agents: [agent], motif: create(:motif, service: agent.service))
      end
    end

    it "displays RDVs whose motif are in the same service as current agent" do
      visit admin_organisation_rdvs_url(organisation, current_agent)
      expect(page).to have_content(current_agent.rdvs.last.motif.name)
      expect(page).to have_content(agent_from_same_service.rdvs.last.motif.name)
      expect(page).not_to have_content(agent_from_other_service.rdvs.last.motif.name)
    end
  end

  context "when a RDV user is soft deleted" do
    let!(:active_user) { create(:user) }
    let!(:deleted_user) { create(:user) }

    before do
      create(:rdv, organisation: organisation, agents: [current_agent], users: [active_user])
      create(:rdv, organisation: organisation, agents: [current_agent], users: [deleted_user])

      deleted_user.soft_delete
    end

    it "displays deleted users without a link to their profile" do
      visit admin_organisation_rdvs_url(organisation, current_agent)

      # Active user has a link to her profile
      path_to_active_user_profile = admin_organisation_user_path(organisation_id: organisation.id, id: active_user.id)
      expect(page).to have_link(active_user.full_name, href: path_to_active_user_profile)

      # Deleted user has a link to her profile
      path_to_deleted_user_profile = admin_organisation_user_path(organisation_id: organisation.id, id: deleted_user.id)
      expect(page).to have_content("#{deleted_user}Supprimé")
      expect(page.body).not_to include(path_to_deleted_user_profile)
    end
  end
end
