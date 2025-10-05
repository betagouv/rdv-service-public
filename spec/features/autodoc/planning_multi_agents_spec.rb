RSpec.describe "Nouveau planning / planning multi-agents", js: true do
  let!(:organisation) { create(:organisation) }
  let!(:agent_admin) { create(:agent, first_name: "Justine", last_name: "Admin", admin_role_in_organisations: [organisation]) }
  let!(:agent_basique) { create(:agent, first_name: "Loïc", last_name: "Basique", basic_role_in_organisations: [organisation]) }

  before do
    monday_at_9 = Time.zone.now.beginning_of_week.to_date.at(Tod::TimeOfDay.parse("09:00"))
    create(:rdv, :no_service, organisation:, starts_at: monday_at_9, agents: [agent_admin], users: [create(:user, last_name: "DEJUSTINE")])
    create(:rdv, :no_service, organisation:, starts_at: monday_at_9, agents: [agent_basique], users: [create(:user, last_name: "DELOIC")])

    create(:plage_ouverture, agent: agent_admin, organisation:, title: "Plage de Justine")
    create(:plage_ouverture, agent: agent_basique, organisation:, title: "Plage de Loïc")

    create(:absence, agent: agent_admin, title: "Indispo de Justine")
    create(:absence, agent: agent_basique, title: "Indispo de Loïc")
  end

  specify do
    login_as(agent_basique, scope: :agent)
    doc = Autodoc.start_scenario("Nouveau planning / planning multi-agents", self)

    #
    # FEATURE FLAG DÉSACTIVÉ : on fait un tour du planning
    #

    doc.start_section("Pour un agent qui n'a pas activé la feature")
    visit admin_organisation_planning_agenda_path(organisation)
    expect(page).to have_content("Votre agenda")
    doc.add_screenshot(page, text: "L'agenda classique est affiché, et le menu de planning dépliant est affiché à gauche",
                             wait_for: "DELOIC")

    click_on "Plages d'ouverture"
    doc.add_screenshot(page, text: "L'agent peut voir ses plages d'ouverture",
                             wait_for: "Plage de Loïc")

    click_on "Indisponibilités"
    doc.add_screenshot(page, text: "L'agent peut voir ses indisponibilité",
                             wait_for: "Indispo de Loïc")

    find("#select2-planning_agent_select-container").click
    find(%(.select2-results__option), text: "ADMIN Justine").click
    doc.add_screenshot(page, text: "Il est possible de sélectionner un autre agent via le menu de gauche (ici on sélectionne Justine)",
                             wait_for: "Indispo de Justine")

    click_on "Plages d'ouverture"
    doc.add_screenshot(page, text: "Lorsque l'on navigue vers les plages, on garde l'agent sélectionné",
                             wait_for: "Plage de Justine")

    click_on "Agenda"
    doc.add_screenshot(page, text: "Lorsque l'on navigue vers l'agenda, on garde l'agent sélectionné",
                             wait_for: "DEJUSTINE") # On vérifie que le RDV de Justine apparaît bien dans l'agenda

    #
    # FEATURE FLAG ACTIVÉ : on fait un tour du planning
    #

    doc.start_section("Quand l'agent active la feature (actuellement faisable depuis le super-admin)")
    agent_basique.toggle_feature!("new_planning")
    visit admin_organisation_planning_agenda_path(organisation)
    expect(page).to have_content("Planning de")
    doc.add_screenshot(page, text: "Une nouvelle navigation est proposée, où le choix de l'agent et du sous-menu sont dans la page principale et non plus dans le menu",
                             wait_for: "DELOIC") # On vérifie que le RDV de Loïc apparaît bien dans l'agenda

    click_on "Plages d'ouverture"
    doc.add_screenshot(page, text: "L'agent peut voir ses plages d'ouverture",
                             wait_for: "Plage de Loïc")

    click_on "Indisponibilités"
    doc.add_screenshot(page, text: "L'agent peut voir ses indisponibilité",
                             wait_for: "Indispo de Loïc")

    find("#select2-agent_id-container").click
    find(%(.select2-results__option), text: "ADMIN Justine").click
    doc.add_screenshot(page, text: "Il est possible de changer l'agent sélectionné",
                             wait_for: "Indispo de Justine")

    click_on "Plages d'ouverture"
    doc.add_screenshot(page, text: "Lorsque l'on navigue vers les plages, on garde l'agent sélectionné",
                             wait_for: "Plage de Justine")

    click_on "Agenda"
    doc.add_screenshot(page, text: "Lorsque l'on navigue vers l'agenda, on garde l'agent sélectionné",
                             wait_for: "DEJUSTINE") # On vérifie que le RDV de Justine apparaît bien dans l'agenda

    #
    # SÉLECTION MULTI-AGENT : on fait un tour du planning
    #

    doc.start_section("Sélection multi-agent")

    click_on "Sélectionner plusieurs agents"
    find("#planning_agents_select .select2-container").click
    find(%(.select2-results__option), text: "BASIQUE Loïc").click
    find("#submit_agents").click
    doc.add_screenshot(page, text: "Il est possible de sélectionner plusieurs agents",
                             wait_for: "Revenir à mon agenda")

    click_on "Plages d'ouverture"
    expect(page).to have_content(["Justine ADMIN", "1 plage d'ouverture", "Loïc BASIQUE", "1 plage d'ouverture"].join("\n"))
    doc.add_screenshot(page, text: "La section des plages d'ouvertures liste tous les agents sélectionnés.")

    click_on "Indisponibilités"
    expect(page).to have_content(["Justine ADMIN", "1 indisponibilité", "Loïc BASIQUE", "1 indisponibilité"].join("\n"))
    doc.add_screenshot(page, text: "La section des indisponibilités liste tous les agents sélectionnés.")
  end
end
