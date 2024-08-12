RSpec.describe "Agent can see rdvs in their calendar", :js do
  context "for a rdv collectif" do
    it "shows the number of participants and the max number of participants" do
      organisation = create(:organisation)
      # display saturday to see 6 week days
      agent = create(:agent, basic_role_in_organisations: [organisation], display_saturdays: true)
      login_as(agent, scope: :agent)

      # Create a RDV this week, monday at 14:00, so that it will show on the calendar
      starts_at = Time.zone.now.beginning_of_week.change({ hour: 14 })

      motif = create(:motif, :collectif, organisation: organisation, service: agent.services.first, name: "Atelier collectif")
      create(
        :rdv,
        agents: [agent],
        motif: motif,
        organisation: organisation,
        name: "Traitement de texte",
        users: create_list(:user, 2),
        max_participants_count: 3,
        starts_at: starts_at
      )

      visit admin_organisation_agent_agenda_path(organisation, agent)
      expect(page).to have_content("Atelier collectif : Traitement de texte (2/3)")
    end
  end
end
