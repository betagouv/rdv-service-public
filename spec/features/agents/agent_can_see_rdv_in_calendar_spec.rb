# frozen_string_literal: true

describe "Agent can see rdvs in their calendar", js: true do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let(:now) { Time.zone.parse("20220420 13:00") }

  before do
    travel_to(now)
    login_as(agent, scope: :agent)
  end

  context "for a rdv collectif" do
    let(:motif) { create(:motif, :collectif, organisation: organisation, service: agent.service, name: "Atelier collectif") }
    let!(:rdv) do
      create(:rdv, agents: [agent], motif: motif, organisation: organisation, name: "Traitement de texte",
                   users: create_list(:user, 2), max_participants_count: 3, starts_at: now + 2.hours)
    end

    it "shows the number of participants and the max number of participants" do
      visit admin_organisation_agent_agenda_path(organisation, agent)
      expect(page).to have_content("Atelier collectif : Traitement de texte (2/3)")
    end
  end
end
