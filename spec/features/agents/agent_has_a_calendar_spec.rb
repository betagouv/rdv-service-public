RSpec.describe "Agent calendar displays rdvs and plages" do
  it "shows the number of participants and the max number of participants of a rdv collectif", js: true do
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

    visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
    expect(page).to have_content("Atelier collectif : Traitement de texte (2/3)")
  end

  it "shows plages in weekly and monthly views", js: true do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    login_as(agent, scope: :agent)

    create(
      :plage_ouverture,
      :no_recurrence,
      agent: agent,
      organisation: organisation,
      first_day: Time.zone.now.beginning_of_week.monday + 1.day, # la plage est ouverte pour mardi de la semaine courante
      start_time: "09:00",
      end_time: "12:00",
      title: "Ceci est le libellé de la plage"
    )
    visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
    expect(page).to have_content("Ceci est le libellé de la plage")

    click_button "Mois"
    expect(page).to have_content("Ceci est le libellé de la plage")

    # On vérifie que la plage n'est pas affichée deux mois plus tard :
    # cela permet de s'assurer que la spec n'est pas en faux-positif
    # à cause de race conditions liées aux appels Ajax.
    find(".fc-next-button").click
    find(".fc-next-button").click
    expect(page).not_to have_content("Ceci est le libellé de la plage")
    # On revient au mois courant pour re-vérifier
    find(".fc-prev-button").click
    find(".fc-prev-button").click
    expect(page).to have_content("Ceci est le libellé de la plage")
  end

  describe "realtime refreshes" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before do
      allow_any_instance_of(Agent).to receive(:realtime_agenda_refresh?).and_return(true) # rubocop:disable RSpec/AnyInstance
      login_as(agent, scope: :agent)
    end

    it "refreshes RDVs", js: true do
      # Create a RDV this week, monday at 14:00, so that it will show on the calendar
      starts_at = Time.zone.now.beginning_of_week.change({ hour: 14 })

      motif = create(:motif, organisation: organisation, name: "Atelier collectif")
      francis = create(:user, first_name: "Francis", last_name: "Factice")

      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      sleep 0.1 # on attend 100ms que la connexion Websocket se fasse

      rdv = create(:rdv, agents: [agent], motif:, organisation:, users: [francis], starts_at:)
      expect(page).to have_selector(".fc-event", text: "14:00 - 14:45\nFrancis FACTICE")

      rdv.update!(starts_at: rdv.starts_at + 1.hour)
      expect(page).to have_selector(".fc-event", text: "15:00 - 15:45\nFrancis FACTICE")

      gaston = create(:user, first_name: "Gaston", last_name: "Bidon")
      create(:participation, rdv:, user: gaston)
      expect(page).to have_selector(".fc-event", text: "15:00 - 15:45\nFrancis FACTICE et Gaston BIDON")

      rdv.participations.find { _1.user == francis }.destroy!
      expect(page).to have_selector(".fc-event", text: "15:00 - 15:45\nGaston BIDON")

      # Quand on assigne le RDV à un autre agent, il disparaît.
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv.agents = [other_agent]
      expect(page).to have_no_content(".fc-event")

      # On va voir l'agenda de l'autre agent et on vérifie que le RDV disparaît bien au destroy.
      visit admin_organisation_planning_agenda_path(organisation, agent_id: other_agent.id)
      expect(page).to have_selector(".fc-event", text: "15:00 - 15:45\nGaston BIDON")
      rdv.destroy!
      expect(page).to have_no_content(".fc-event")
    end

    it "refreshes plages", js: true do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      sleep 0.1 # on attend 100ms que la connexion Websocket se fasse

      plage = create(:plage_ouverture, organisation:, agent:, title: "Ma plage", first_day: Time.zone.now.beginning_of_week.to_date)
      expect(page).to have_selector(".fc-event.fc-bg-event", text: "Ma plage")

      plage.update!(title: "Ma SUPER plage")
      expect(page).to have_selector(".fc-event.fc-bg-event", text: "Ma SUPER plage")

      plage.destroy!
      expect(page).to have_no_content(".fc-event")
    end

    it "refreshes absence", js: true do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      sleep 0.1 # on attend 100ms que la connexion Websocket se fasse

      absence = create(:absence, agent:, title: "Mon indispo", first_day: Time.zone.now.beginning_of_week.to_date)
      expect(page).to have_selector(".fc-event", text: "Mon indispo")

      absence.update!(title: "Ma SUPER indispo")
      expect(page).to have_selector(".fc-event", text: "Ma SUPER indispo")

      absence.destroy!
      expect(page).to have_no_content(".fc-event")
    end

    it "fonctionne quand on change de page et qu'on revient", js: true do
      agent.enable_feature!(Agent::FeatureFlags::NEW_PLANNING)

      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      expect(page).to have_content("Planning de")

      click_on "Statistiques"
      expect(page).to have_content("Statistiques de") # on vérifie que Turbolinks nous a bien changé la page

      click_on "Planning"
      expect(page).to have_content("Planning de") # on vérifie que Turbolinks nous a bien changé la page
      sleep 0.1 # on attend 100ms que la connexion Websocket se fasse

      create(:absence, agent:, title: "Mon indispo", first_day: Time.zone.now.beginning_of_week.to_date)
      expect(page).to have_selector(".fc-event", text: "Mon indispo")
    end
  end
end
