RSpec.describe "User can select a creneau" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  let!(:territory92) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory: territory92) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:service) { create(:service) }

  before { travel_to(now) }

  context "when the next creneau is after the max booking delay" do
    let!(:motif) { create(:motif, name: "RSA Orientation", organisation: organisation, max_public_booking_delay: 7.days, restriction_for_rdv: nil, service: service) }
    # Avec un seul motif on passe par le choix d'un lieu.
    # Avec deux motifs, on affiche directement la disponibilité.
    let!(:autre_motif) { create(:motif, organisation: organisation, max_public_booking_delay: 7.days, service: service) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:autre_plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [autre_motif], lieu: lieu, organisation: organisation) }

    it "shows that no creneau is available", js: true do
      visit root_path
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      # Fake autocomplete
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      find("h3", text: motif.name).click

      expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé.")
    end

    context "when the user is invited" do
      let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", motifs: [motif]) }
      let!(:rdv_invitation_token) { SecureRandom.uuid }
      let!(:user) { create(:user, rdv_invitation_token:) }

      it "shows that no creneau is available" do
        visit prendre_rdv_path(motif_category_short_name: "rsa_orientation", invitation_token: rdv_invitation_token, lieu_id: lieu.id, departement: "92", organisation_ids: [organisation.id])

        expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre invitation n'a été trouvé")
      end
    end
  end

  context "when two agents are available for the given motif" do
    let!(:motif) { create(:motif, name: "RSA Orientation", organisation: organisation) }
    let!(:plage_ouverture1) { create(:plage_ouverture, first_day: Time.zone.tomorrow, motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, first_day: Time.zone.tomorrow, motifs: [motif], lieu: lieu, organisation: organisation) }

    it "does not show duplicate creneaux" do
      visit public_link_to_org_path(organisation_id: organisation.id)

      click_on("RSA Orientation") # choix du motif
      click_on("Prochaine disponibilité le") # choix du lieu
      displayed_creneaux = page.all("a", text: "08:00")
      expect(displayed_creneaux.size).to eq(1)
    end
  end
end
