RSpec.describe "Prendre RDV pour un usager en tant que prescripteur externe", js: true do
  let!(:territory) { create(:territory, departement_number: "75") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let(:bookable_by) { "everyone" }
  let!(:motif) do
    create(:motif, organisation: organisation, service: agent.services.first, bookable_by: bookable_by, instruction_for_rdv: "Instructions après confirmation", name: "Formation emails")
  end
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let!(:plage_ouverture) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], lieu: lieu) }

  specify do
    doc = Autodoc.start_scenario("Prendre RDV pour un usager en tant que prescripteur externe", self, category: "3) Produit")

    doc.start_section("Côté agent prescripteur")
    doc.add_text("Contexte : Je suis un agent prescripteur qui ne dispose pas de compte sur RDV Service Public et je veux prendre un RDV pour un usager")

    visit "http://www.rdv-mairie-test.localhost/org/#{organisation.id}/"
    doc.add_screenshot(page,
                       text: "Je choisis le motif de rendez-vous",
                       wait_for: "Formation emails")

    click_on "Formation emails"
    doc.add_screenshot(page,
                       text: "Je choisis un lieu de rendez-vous",
                       wait_for: "Bureau")
    click_on "Bureau"

    doc.add_screenshot(page,
                       text: "Je choisis une date et un créneau horaire",
                       wait_for: "08:00")

    click_on "08:00"

    Capybara.page.current_window.resize_to(1280, 1280)
    doc.add_screenshot(page,
                       text: "Je clique sur le lien en bas de la page indiquant que je suis un prescripteur : « Je suis un prescripteur qui oriente un bénéficaire »",
                       wait_for: "Je suis un prescripteur qui oriente un bénéficiaire")

    click_on "Je suis un prescripteur qui oriente un bénéficiaire"

    doc.add_screenshot(page,
                       text: "Je saisis mes informations",
                       wait_for: "Vos coordonnées de prescripteur")

    fill_in "Votre prénom", with: "Paul"
    fill_in "Votre nom", with: "Durand"
    fill_in "Votre email professionnel", with: "paul.durand@france.fr"
    click_on "Continuer"

    doc.add_screenshot(page,
                       text: "Je saisis les informations de l'usager",
                       wait_for: "Bénéficiaire")

    fill_in "Prénom", with: "Jean"
    fill_in "Nom", with: "Dupont"
    fill_in "Téléphone mobile", with: "0612345678"
    click_on "Confirmer le rendez-vous"

    doc.add_screenshot(page,
                       text: "Le rendez-vous est confirmé. Je vois le récapitulatif et je peux annuler le rendez-vous.")
  end
end
