RSpec.describe "Migration depuis RDV Aide Numérique vers RDV Service Public", js: true do
  # Pour simplifier les test, on crée deux agents sur la même instance
  let(:organisation) do
    create(:organisation, name: "France Service de Montreuil")
  end

  let!(:agent) do
    create(:agent, first_name: "Francis", last_name: "Factice", basic_role_in_organisations: [organisation])
  end
  let!(:oauth_application) { create(:oauth_application, name: "RDV Aide Numérique") }

  let!(:absence_representing_rdv) { create(:absence, :no_recurrence, agent: agent) }

  before do
    create(:external_reference, item: absence_representing_rdv, external_id: "#{CopyPlanningToNewInstanceJob::CopyRdvAsAbsenceJob::EXTERNAL_ID_PREFIX}1", oauth_application:)
    create(:motif, :collectif, organisation:)
  end

  specify do
    doc = Autodoc.start_scenario("Liens vers RDV Aide Numérique après une migration", self, accessibility_checks: false)

    doc.start_section("Introduction")
    doc.add_text(<<~TEXT
      Lors d'une copie des données depuis RDV Aide Numérique vers RDV Service Public, les rendez-vous ne sont pas copiés parce que ça serait trop compliqué à gérer.
      Par contre, on crée pour chaque rendez-vous à venir sur RDV Aide Numérique une indisponibilité correspondant sur RDV Service Public.
      Pour rendre ce fonctionnement plus facile à comprendre, on ajoute différentes explications dans le produit.
    TEXT
                )

    login_as(agent, scope: :agent)

    doc.start_section("Liste des rendez-vous")
    visit admin_organisation_rdvs_path(organisation)

    doc.add_screenshot(page,
                       text: "On ajoute une bannière s'il y a des absences à venir qui sont liées à des RDV sur l'ancienne instance",
                       wait_for: "Il est possible que vous ayez des RDV prévus sur RDV Aide Numérique avant votre migration sur RDV Service Public.")

    doc.start_section("Liste des rendez-vous collectif")
    visit admin_organisation_rdvs_collectifs_path(organisation)

    doc.add_screenshot(page,
                       text: "On ajoute une bannière similaire",
                       wait_for: "Il est possible que vous ayez des RDV collectifs prévus sur RDV Aide Numérique avant votre migration sur RDV Service Public.")

    doc.start_section("Détails de l'indisponibilité")

    visit edit_admin_organisation_planning_absence_path(organisation, absence_representing_rdv)

    doc.add_screenshot(page,
                       text: "On ajoute une bannière similaire sur la page de détails de l'indispo. C'est sur cette page qu'on arrive si on clique sur l'indispo dans le calendrier.",
                       wait_for: "Cette indisponibilité correspond à un rendez-vous pris sur RDV Aide Numérique avant la migration sur RDV Service Public.")
  end
end
