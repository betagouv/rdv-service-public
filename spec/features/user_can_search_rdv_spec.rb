describe "User can search for rdvs" do
  let!(:motif) { create(:motif, name: "Vaccination", online: true) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }
  let!(:user) { create(:user) }
  let!(:organisation) { plage_ouverture.organisation }

  before do
    visit root_path
  end

  scenario "default", js: true do
    # Step 1
    expect_page_h1("Prenez rendez-vous en ligne avec\nvotre Maison Départementale des Solidarités")
    fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
    page.execute_script("document.querySelector('#search_departement').value = '92'")
    click_button("Choisir cette adresse")

    # Step 2
    expect_page_h1("Prenez rendez-vous en ligne avec\nvotre Maison Départementale des Solidarités du 92")
    select(motif.name, from: 'search_motif')
    click_button("Choisir ce motif")

    # Step 3
    expect(page).to have_content("Modifier le motif")
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

    click_button('Continuer')

    # Step 5
    click_link('Aller à la liste de vos rendez-vous')

    # Step 6
    expect(page).to have_content("Vos rendez-vous")
    expect(page).to have_content(motif.name)
    expect(page).to have_content(lieu.address)
    expect(page).to have_content("11h00")
  end

  def click_first_suggestion
    find('.ap-suggestion', match: :first).click
  end

  def select_user(user)
    select(user.full_name, from: 'rdv_user_ids')
  end

  def expect_page_h1(title)
    expect(page).to have_selector('h1', text: title)
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
