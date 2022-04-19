# frozen_string_literal: true

describe "Agent can see rdvs in their calendar", js: true do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  before { login_as(agent, scope: :agent) }

  context "for a rdv collectif" do
    let(:motif) { create(:motif, :collectif, organisation: organisation, service: agent.service, name: "Atelier collectif") }
    let!(:rdv) do
      create(:rdv, agents: [agent], motif: motif, organisation: organisation, name: "Traitement de texte",
                   users: create_list(:user, 2), max_participants_count: 3, starts_at: starts_at)
    end

    let(:starts_at) do
      Time.zone.today + 12.hours # This date is always visible on the calendar, so the spec is green no matter when it runs (we can't easily stub the time for the browser)
    end

    it "shows the number of participants and the max number of participants" do
      visit admin_organisation_agent_agenda_path(organisation, agent)
      expect(page).to have_content("Atelier collectif : Traitement de texte (2/3)")
    end
  end
end
