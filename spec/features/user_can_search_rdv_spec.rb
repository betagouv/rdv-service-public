describe "User can search for rdvs" do
  let!(:motif) { create(:motif, name: "Vaccination", online: true) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }
  let!(:user) { create(:user) }
  let(:organisation) { plage_ouverture.organisation }

  before do
    visit root_path
  end

  scenario "default" do
    # Step 1
    expect(page.status_code).to be(200)
    expect_page_h1("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités")
    fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
    # Improve with click on suggestion instead of filling an hidden input
    find(:xpath, "//input[@id='search_departement']", visible: false).set("92")
    # click_first_suggestion
    click_button("Choisir cette adresse")

    # Step 2
    expect(page.status_code).to be(200)
    expect_page_h1("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités du 92")
    select(motif.name, from: 'search_motif')
    click_button("Choisir ce motif")

    # Step 3
    expect(page).to have_content("Modifier le motif")
    expect(page).to have_content(lieu.name)
    expect(page).to have_content(lieu2.name)

    expect(page).to have_content(lieu.name)

    login_as(user, scope: :user)
    first(:link, "11:00").click

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

  def select_pro(pro)
    select(pro.full_name_and_service, from: 'rdv_pro_ids')
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
