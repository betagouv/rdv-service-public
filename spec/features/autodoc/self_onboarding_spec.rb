RSpec.describe "Embarquement en autonomie pour les admins", js: true do
  include ActionView::Helpers::SanitizeHelper

  let(:agent) do
    create(:agent, admin_role_in_organisations: [organisation],
                   first_name: "Francis",
                   last_name: "Factice",
                   email: "francis.factice@demo-rdv-service-public.gouv.fr")
  end
  let(:organisation) { create(:organisation, name: "Mairie de Montreuil") }

  before { login_as(agent, scope: :agent) }

  specify do
    doc = Autodoc.start_scenario("Embarquement guidé", self, accessibility_checks: false, category: "2) Embarquement")

    doc.start_section("Pour un admin")

    text = <<~TEXT
      <p>
        On veut guider les agents qui ouvrent un compte en autonomie pour qu'ils puissent se servir du produit sans avoir besoin de suivre une formation.
      </p>
      <p>
        On part ici d'un compte qui vient d'être ouvert. L'agent a reçu un email qui l'envoie vers la configuration de son organisation qui n'a pas encore de motifs ou de lieux
      </p>
    TEXT
    doc.add_text(sanitize(text))

    visit admin_organisation_configuration_url(organisation, host: "http://www.rdv-service-public-test.localhost")

    doc.add_screenshot(page,
                       text: "On affiche une bannière qui indique que la première action à prendre est de créer un motif",
                       wait_for: "Pour commencer, vous pouvez créer votre premier motif de rendez-vous")

    click_on "Créer un motif"

    fill_in "Nom du motif", with: "Accompagnement individuel"

    doc.add_screenshot(page, text: "L'agent remplit le formulaire de motif.")

    click_on "Créer le motif"

    doc.add_screenshot(page,
                       text: "Une bannière indique maintenant qu'il faut ajouter un lieu, puisque le motif est sur place",
                       wait_for: "Vous pouvez maintenant ajouter le lieu")

    click_on "Ajouter un lieu"

    fill_in  "Nom", with: "Mairie de Montreuil"
    fill_in "Adresse", with: "1 Place Jean Jaurès, 93100 Montreuil"

    page.execute_script("document.querySelector('input#lieu_latitude').value = '48.583844'")
    page.execute_script("document.querySelector('input#lieu_longitude').value = 7.735253")

    doc.add_screenshot(page, text: "L'agent renseigne les informations du lieu.")

    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "Une bannière indique maintenant qu'on peut faire un premier rendez-vous ou ouvrir la réservation en ligne.",
                       wait_for: "Tout est prêt pour votre premier rendez-vous")

    click_on "Aller à l'agenda"

    doc.add_screenshot(page,
                       text: "Sur l'agenda on m'incite à créer le premier rendez-vous",
                       wait_for: "Vous pouvez prendre votre premier rendez-vous en cliquant sur l'horaire de votre choix")
  end
end
