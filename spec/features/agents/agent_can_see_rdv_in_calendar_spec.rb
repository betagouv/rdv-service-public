# frozen_string_literal: true

describe "Agent can see rdvs in their calendar", js: true do
  context "for a rdv collectif" do
    it "shows the number of participants and the max number of participants" do
      organisation = create(:organisation)
      # display saturday to see 6 week days
      agent = create(:agent, basic_role_in_organisations: [organisation], display_saturdays: true)
      login_as(agent, scope: :agent)

      # Use today because it not really easy to stub browser time
      today = Time.zone.today
      # force hour to be in visible agenda range
      starts_at = Time.zone.parse("#{today.strftime('%F')} 14:00")
      # move back one day ago one sunday
      starts_at = 1.day.ago if today.strftime("%w").to_i > 6

      motif = create(:motif, :collectif, organisation: organisation, service: agent.service, name: "Atelier collectif")
      create(
        :rdv,
        agents: [agent],
        motif: motif,
        organisation: organisation,
        name: "Traitement de texte",
        users: create_list(:user, 2),
        max_participants_count: 3,
        starts_at: starts_at,
      )

      visit admin_organisation_agent_agenda_path(organisation, agent)
      expect(page).to have_content("Atelier collectif : Traitement de texte (2/3)")
    end
  end
end
