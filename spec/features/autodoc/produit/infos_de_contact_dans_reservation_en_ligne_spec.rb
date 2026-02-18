RSpec.describe "Informatiosn de contact d'une structure lors de la réservation en ligne", js: true do
  let!(:motif) { create(:motif, name: "Suivi de dossier", organisation:) }
  let(:organisation) { create(:organisation, :with_contact) }

  specify do
    doc = Autodoc.start_scenario("Informations de contact lors de la réservation en ligne", self, category: "3) Produit")

    doc.start_section("Réservation en ligne quand il n'y a pas de disponibilités")
    visit admin_organisation_online_booking_path(motif.organisation)

    visit public_link_to_motif_path(public_link_id: motif.public_link_id, motif_slug: motif.slug)

    expect(page).to have_content(organisation.humanized_phone_number)

    doc.add_screenshot(
      page,
      text: "On affiche les infos de contact",
      wait_for: "Vous pouvez contacter"
    )
  end
end
