describe "User can search for rdvs" do
  let!(:motif) { create(:motif, name: "Vaccination") }
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
    expect_page_title("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités")
    fill_in('search_where', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
    # Improve with click on suggestion instead of filling an hidden input
    # fill_in('search_departement', with: "92")
    find(:xpath, "//input[@id='search_departement']", visible: false).set("92")
    # click_first_suggestion
    click_button("Choix d'une localité")

    # Step 2
    expect_page_title("Prenez rendez-vous en ligne avecvotre Maison Départementale des Solidarités du 92")
    select(motif.name, from: 'search_motif')
    click_button("Choix d'un motif")

    # Step 3
    expect(page).to have_content("Modifier le motif")
    expect(page).to have_content(lieu.name)
    expect(page).to have_content(lieu2.name)

  #   select(motif.id.to_s, from: "rdv_motif_id")
  #   click_button('Continuer')
  #
  #   # Step 2
  #   expect_page_title("Choisir la durée et la date")
  #   expect_checked(motif.name)
  #   expect(page).to have_selector("input#rdv_duration_in_min[value='#{motif.default_duration_in_min}']")
  #   fill_in 'Lieu', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes"
  #   fill_in 'Durée en minutes', with: '35'
  #   fill_in 'Commence à', with: '12/10/2019 à 14h15'
  #
  #   select_pro(pro)
  #   select_pro(pro2)
  #   click_button('Continuer')
  #
  #   # Step 3
  #   expect_page_title("Choisir l'usager")
  #   expect_checked("Motif : #{motif.name}")
  #   expect_checked("Lieu : 79 Rue de Plaisance, 92250 La Garenne-Colombes")
  #   expect_checked("Durée : 35 minutes")
  #   expect_checked("Professionnels : #{pro.full_name_and_service} et #{pro2.full_name_and_service}")
  #   expect_checked("Commence le : samedi 12 octobre 2019 à 14h15")
  #
  #   select_user(user)
  #
  #   click_button('Continuer')
  #
  #   expect(user.rdvs.count).to eq(1)
  #   rdv = user.rdvs.first
  #   expect(rdv.users).to contain_exactly(user)
  #   expect(rdv.motif).to eq(motif)
  #   expect(rdv.duration_in_min).to eq(35)
  #   expect(rdv.start_at).to eq(Time.zone.local(2019, 10, 12, 14, 15))
  # end
  #
  # scenario "with a users limit" do
  #   expect_page_title("Choisir le motif")
  #   select(motif_with_limit.id.to_s, from: "rdv_motif_id")
  #   click_button('Continuer')
  #
  #   # Step 2
  #   expect_page_title("Choisir la durée et la date")
  #   expect_checked("Motif : #{motif_with_limit.name}")
  #   select_pro(pro)
  #   fill_in "Limite du nombre d'usagers", with: '4'
  #
  #   click_button('Continuer')
  #
  #   # Step 3
  #   expect_page_title("Choisir l'usager")
  #   expect_checked("4 usagers maximum")
  #
  #   select_user(user)
  #
  #   click_button('Continuer')
  #
  #   expect(user.rdvs.last.max_users_limit).to eq(4)
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
