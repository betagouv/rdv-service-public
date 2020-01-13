describe "User can search for rdvs" do
  let!(:motif) { create(:motif, name: "Vaccination", online: true) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }
  let!(:organisation) { plage_ouverture.organisation }

  describe "default" do
    before do
      visit root_path
    end

    scenario "default", js: true do
      # Step 1
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département")
      fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      click_button("Rechercher")

      # Step 2
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
      select(motif.service.name, from: 'search_service')
      click_button("Choisir ce service")

      # Step 3
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
      select(motif.name, from: 'search_motif')
      click_button("Choisir ce motif")

      # Step 4
      expect(page).to have_content(lieu.name)
      expect(page).to have_content(lieu2.name)
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Login page
      expect(page).to have_content("Se connecter")
      click_link("Je m'inscris")

      # Sign up page
      expect(page).to have_content("Inscription")
      fill_in(:user_first_name, with: "Michel")
      fill_in(:user_last_name, with: "Lapin")
      fill_in('Email', with: "michel@lapin.fr")
      fill_in('Mot de passe', with: "12345678")
      click_button("Je m'inscris")

      # Confirmation email
      open_email('michel@lapin.fr')
      expect(current_email).to have_content("Merci pour votre inscription")
      current_email.click_link("Confirmer mon compte")

      # Login page
      expect(page).to have_content("Se connecter")
      fill_in('Email', with: "michel@lapin.fr")
      fill_in('Mot de passe', with: "12345678")
      click_button("Se connecter")

      # Step 4
      expect(page).to have_content(motif.name)
      expect(page).to have_content(motif.restriction_for_rdv)

      # Add Child
      click_link("Ajouter un enfant")
      expect(page).to have_selector('h4', text: "Ajouter un enfant")
      fill_in('Prénom', with: "Mathieu")
      fill_in('Nom', with: "Lapin")
      fill_in('Date de naissance', with: Date.yesterday)
      click_button('Créer')
      expect(page).to have_content("Mathieu LAPIN")

      click_button('Continuer')

      # Step 5
      expect(page).to have_content("Votre rendez-vous est confirmé")
      expect(page).to have_content(motif.instruction_for_rdv)
      expect(page).not_to have_content("Annuler le RDV")

      click_link('Aller à la liste de vos rendez-vous')

      # Step 6
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(motif.name)
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "with user and child" do
    let!(:user) { create(:user) }
    let!(:child) { create(:user, parent_id: user.id) }

    before do
      travel_to(Time.zone.local(2019, 11, 18))
      login_as(user, scope: :user)
      # visit welcome_motif_path("92", motif.name)
      visit new_users_rdv_path(starts_at: Time.zone.local(2019, 11, 18, 10, 15), motif_name: motif.name, lieu_id: lieu.id, departement: "92", where: "useless")
    end

    after { travel_back }

    scenario "for children", js: true do
      # Step 4
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(child.full_name)

      choose(child.full_name)

      click_button('Continuer')

      click_link('Aller à la liste de vos rendez-vous')

      # Step 6
      expect(page).to have_content(child.full_name)
    end
  end

  def expect_page_h1(title)
    expect(page).to have_selector('h1', text: title)
  end
end
