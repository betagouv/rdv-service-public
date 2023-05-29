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
end
