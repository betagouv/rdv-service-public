RSpec.describe "Agent calendar displays rdvs and plages", js: true do
  it "shows the number of participants and the max number of participants of a rdv collectif" do
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

  it "shows plages in weekly and monthly views" do
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
    visit admin_organisation_agent_agenda_path(organisation, agent)
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
end
