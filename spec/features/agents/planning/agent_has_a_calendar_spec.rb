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

  describe "revient à l'agenda du collègue après avoir consulté / modifié son RDV" do
    let!(:organisation) { create(:organisation) }
    let!(:me) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:colleague) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:motif) { create(:motif, organisation: organisation, name: "Atelier collectif") }
    let!(:rdv) { create(:rdv, agents: [colleague], motif:, organisation:, starts_at: Time.zone.now.beginning_of_week.change({ hour: 14 })) }

    it "quand l'agent courant n'a pas activé le nouveau planning", js: true do
      login_as(me, scope: :agent)
      visit admin_organisation_planning_agenda_path(organisation, agent_id: colleague.id)

      click_on rdv.users.first.full_name # on clique sur le RDV dans l'agenda
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}?contextual_agent_ids=#{colleague.id}")

      # On vérifie qu'un clic sur Agenda nous ramène bien sur l'agenda du collègue
      click_on "Planning"
      expect(page).to have_content("Planning de\n#{colleague.reverse_full_name}")
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/planning/agenda?agent_id=#{colleague.id}")
    end

    it "quand l'agent courant a activé le nouveau planning", js: true do
      login_as(me, scope: :agent)
      visit admin_organisation_planning_agenda_path(organisation, agent_id: colleague.id)

      click_on rdv.users.first.full_name # on clique sur le RDV dans l'agenda
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}?contextual_agent_ids=#{colleague.id}")

      # On vérifie qu'un clic sur Agenda nous ramène bien sur l'agenda du collègue
      click_on "Planning"
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/planning/agenda?agent_id=#{colleague.id}")
    end
  end

  describe "realtime refreshes" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before do
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
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      expect(page).to have_content("Planning de")

      click_on "Statistiques"
      expect(page).to have_content("Statistiques de")

      click_on "Planning"
      expect(page).to have_content("Planning de")
      sleep 0.5 # on attend que la connexion Websocket se fasse

      create(:absence, agent:, title: "Mon indispo", first_day: Time.zone.now.beginning_of_week.to_date)
      expect(page).to have_selector(".fc-event", text: "Mon indispo")
    end
  end

  describe "création de RDV depuis l'agenda" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before do
      login_as(agent, scope: :agent)
    end

    it "fonctionne depuis la vue mensuelle", js: true do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      click_button "Mois"
      monday = Time.zone.now.beginning_of_week.to_date
      find(%(.fc-daygrid-day[data-date="#{monday}"])).click
      expect(page).to have_content("Nouveau RDV pour le #{I18n.l(monday, format: '%-d/%m/%Y')} à 00:00")
    end

    it "fonctionne depuis la vue semaine", js: true do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      click_button "Semaine"
      # Je ne sais pas comment faire cliquer la spec sur la colonne du lundi, elle clique au milieu de l'élément donc sur le mercredi.
      wednesday = Time.zone.now.beginning_of_week.to_date + 2
      find('.fc-timegrid-slot-lane[data-time="08:30:00"]').click
      expect(page).to have_content("Nouveau RDV pour le #{I18n.l(wednesday, format: '%-d/%m/%Y')} à 08:30")
    end

    it "fonctionne depuis la vue jour", js: true do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      find(".fc-next-button").click
      click_button "Journée"
      find('.fc-timegrid-slot-lane[data-time="08:30:00"]').click
      monday_next_week = Time.zone.today.beginning_of_week + 1.week
      expect(page).to have_content("Nouveau RDV pour le #{I18n.l(monday_next_week, format: '%-d/%m/%Y')} à 08:30")
    end
  end

  describe "apparence de l'agenda" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before do
      login_as(agent, scope: :agent)
    end

    it "affiche le nom des jour en en-tête", js: true do
      Capybara.using_driver(:playwright_guadeloupe) do
        page.driver.with_playwright_page { _1.clock.pause_at(Time.zone.parse("2026-03-15 08:00")) }
        visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)

        # vue semaine
        expected_header = ["lun. 9", "mar. 10", "mer. 11", "jeu. 12", "ven. 13"]
        actual_headers = find_all(".fc-col-header-cell-cushion").map(&:text)
        expect(actual_headers).to eq(expected_header)

        # vue mois
        click_on("Mois")
        expected_header = %w[lundi mardi mercredi jeudi vendredi]
        actual_headers = find_all(".fc-col-header-cell-cushion").map(&:text)
        expect(actual_headers).to eq(expected_header)
      end
    end
  end
end
