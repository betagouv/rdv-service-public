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
    expect_page_title("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités")
    fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
    # Improve with click on suggestion instead of filling an hidden input
    find(:xpath, "//input[@id='search_departement']", visible: false).set("92")
    # click_first_suggestion
    click_button("Choix d'une localité")

    # Step 2
    expect(page.status_code).to be(200)
    expect_page_title("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités du 92")
    select(motif.name, from: 'search_motif')
    click_button("Choix d'un motif")

    # Step 3
    expect(page).to have_content("Modifier le motif")
    expect(page).to have_content(lieu.name)
    expect(page).to have_content(lieu2.name)
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

  def expect_page_title(title)
    expect(page).to have_selector('h1', text: title)
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
