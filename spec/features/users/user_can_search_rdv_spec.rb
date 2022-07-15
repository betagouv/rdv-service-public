# frozen_string_literal: true

describe "User can search for rdvs" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  let!(:territory92) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory: territory92) }
  let!(:motif) { create(:motif, name: "Vaccination", reservable_online: true, organisation: organisation, restriction_for_rdv: nil) }
  let!(:autre_motif) { create(:motif, name: "Consultation", reservable_online: true, organisation: organisation, restriction_for_rdv: nil) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
  let!(:autre_plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [autre_motif], lieu: lieu, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif], lieu: lieu2, organisation: organisation) }

  before do
    travel_to(now)
  end

  describe "default" do
    it "default", js: true do
      visit root_path
      # Step 1
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département")
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      # fake algolia autocomplete to pass on Circle ci
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      # Step 3
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
      find("h3", text: motif.name).click

      # Step 4
      expect(page).to have_content(lieu.name)
      expect(page).to have_content(lieu2.name)

      # Step 5
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Login page
      click_link("Je m'inscris")

      # Sign up page
      expect(page).to have_content("Inscription")
      fill_in(:user_first_name, with: "Michel")
      fill_in(:user_last_name, with: "Lapin")
      fill_in("Email", with: "michel@lapin.fr")
      click_button("Je m'inscris")

      # Confirmation email
      open_email("michel@lapin.fr")
      expect(current_email).to have_content("Merci pour votre inscription")
      current_email.click_link("Confirmer mon compte")

      # Password reset page after confirmation
      expect(page).to have_content("Votre compte a été validé")
      expect(page).to have_content("Définir mon mot de passe")
      fill_in(:password, with: "12345678")
      click_button("Enregistrer")

      # Step 4
      expect(page).to have_content("Vos informations")
      fill_in("Date de naissance", with: DateTime.yesterday.strftime("%d/%m/%Y"))
      fill_in("Nom de naissance", with: "Lapinou")
      click_button("Continuer")

      # Step 5
      expect(page).to have_content("Vaccination")
      expect(page).to have_content("Michel LAPIN (Lapinou)")

      # Add relative
      click_link("Ajouter un proche")
      expect(page).to have_selector("h1", text: "Ajouter un proche")
      fill_in("Prénom", with: "Mathieu")
      fill_in("Nom", with: "Lapin")
      fill_in("Date de naissance", with: Date.yesterday)
      click_button("Enregistrer")
      expect(page).to have_content("Mathieu LAPIN")

      click_button("Continuer")

      # Step 6
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("Mathieu LAPIN")
      click_link("Confirmer mon RDV")

      # Step 7
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(lieu.address)
      expect(page).to have_content(motif.name)
      expect(page).to have_content("11h00")
    end
  end

  def expect_page_h1(title)
    expect(page).to have_selector("h1", text: title)
  end
end
