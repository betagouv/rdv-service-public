RSpec.describe "Lien de réservation direct pour un motif", js: true do
  let!(:motif) { create(:motif, name: "Suivi de dossier") }
  let(:lieu) { create(:lieu, organisation: motif.organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation]) }

  before do
    create(:plage_ouverture, motifs: [motif], lieu:)
    login_as(agent, scope: :agent)
  end

  specify do
    doc = Autodoc.start_scenario("Lien de prise de rendez-vous pour un motif spécifique", self, category: "3) Produit")

    doc.start_section("Pour un motif ouvert à la réservation en ligne, avec des créneaux disponible")
    visit admin_organisation_online_booking_path(motif.organisation)

    Capybara.page.current_window.resize_to(1280, 1000)

    doc.add_screenshot(page, text: "J'ouvre la page de configuration de la réservation en ligne.",
                             wait_for: "Réservation en ligne")

    click_on "Suivi de dossier"
    doc.add_screenshot(page, text: "J'ouvre les détails de ce motif.",
                             wait_for: "Ce lien permet de prendre rendez-vous pour ce motif.")

    Capybara.page.current_window.resize_to(1280, 720)

    within(".card-body", match: :first) do
      visit find("a[target='_blank']").text # On fait un visit plutôt que d'ouvrir le lien dans un nouvel onglet
    end

    doc.add_screenshot(
      page,
      text: "En cliquant sur le lien, j'arrive sur la prise de rendez-vous pour ce motif. Si d'autres motifs sont ouverts, l'usager pourra quand même revenir en arrière et choisir un autre motif.",
      wait_for: "Sélectionnez un lieu de RDV"
    )
  end
end
