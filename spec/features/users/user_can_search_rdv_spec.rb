describe "User can search for rdvs" do
  let!(:motif) { create(:motif, name: "Vaccination", reservable_online: true) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu2) }
  let!(:organisation) { plage_ouverture.organisation }

  describe "default" do
    before do
      visit root_path
    end

    scenario "default", js: true do
      # Step 1
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département")
      fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      # fake algolia autocomplete to pass on Circle ci
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      # Step 2
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
      select(motif.service.name, from: 'search_service')
      click_button("Choisir ce service")

      # Step 3
      expect_page_h1("Prenez rendez-vous en ligne\navec votre département le 92")
      select(motif.name, from: 'search_motif_name')
      click_button("Choisir ce motif")

      # Step 4
      expect(page).to have_content(lieu.name)
      expect(page).to have_content(lieu2.name)

      # Step 5
      find(".card-title", text: /#{lieu.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(lieu.name)
      first(:link, "11:00").click

      # Restriction Page
      expect(page).to have_content("À lire avant de prendre un rendez-vous")
      expect(page).to have_content(motif.restriction_for_rdv)
      click_link("Accepter")

      # Login page
      expect(page).to have_content("Se connecter")
      click_link("Je m'inscris")

      # Sign up page
      expect(page).to have_content("Inscription")
      fill_in(:user_first_name, with: "Michel")
      fill_in(:user_last_name, with: "Lapin")
      fill_in('Email', with: "michel@lapin.fr")
      fill_in(:password, with: "12345678")
      click_button("Je m'inscris")

      # Confirmation email
      open_email('michel@lapin.fr')
      expect(current_email).to have_content("Merci pour votre inscription")
      current_email.click_link("Confirmer mon compte")

      # Login page
      expect(page).to have_content("Se connecter")
      fill_in('Email', with: "michel@lapin.fr")
      fill_in(:password, with: "12345678")
      click_button("Se connecter")

      # Step 4
      expect(page).to have_content("Vos informations")
      fill_in('Date de naissance', with: Date.tomorrow)
      click_button('Continuer')
      expect(page).to have_content("Date de naissance est invalide")
      fill_in('Date de naissance', with: Date.yesterday)
      fill_in('Nom de naissance', with: "Lapinou")
      expect(page).to have_field('Adresse', with: '79 Rue de Plaisance, 92250 La Garenne-Colombes')
      click_button('Continuer')

      # Step 5
      expect(page).to have_content(motif.name)
      expect(page).to have_content("Michel LAPIN (LAPINOU)")

      # Add relative
      click_link("Ajouter un proche")
      expect(page).to have_selector('h4', text: "Ajouter un proche")
      fill_in('Prénom', with: "Mathieu")
      fill_in('Nom', with: "Lapin")
      fill_in('Date de naissance', with: Date.yesterday)
      click_button('Créer')
      expect(page).to have_content("Mathieu LAPIN")

      click_button('Continuer')

      # Step 6
      expect(page).to have_content("Informations de contact")
      expect(page).to have_content("Mathieu LAPIN")
      click_link('Confirmer mon RDV')

      # Step 7
      expect(page).to have_content("Vos rendez-vous")
      expect(page).to have_content(motif.name)
      expect(page).to have_content(lieu.address)
      expect(page).to have_content("11h00")
    end
  end

  describe "with user and relative" do
    let!(:user) { create(:user) }
    let!(:relative) { create(:user, responsible_id: user.id) }

    before do
      travel_to(Time.zone.local(2019, 11, 18))
      login_as(user, scope: :user)
      visit new_users_rdv_wizard_step_path(step: 2, starts_at: Time.zone.local(2019, 11, 18, 10, 15), motif_id: motif.id, lieu_id: lieu.id, departement: "92", where: "useless")
    end

    after { travel_back }

    scenario "for relatives", js: true do
      # Step 4
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(relative.full_name)

      choose(relative.full_name)

      click_button('Continuer')

      click_link('Confirmer mon RDV')

      # Step 6
      expect(page).to have_content(relative.full_name)
    end
  end

  def expect_page_h1(title)
    expect(page).to have_selector('h1', text: title)
  end
end
