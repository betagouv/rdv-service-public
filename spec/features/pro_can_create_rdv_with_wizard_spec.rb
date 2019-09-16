describe "Pro can create a Rdv with wizard" do
  let!(:pro) { create(:pro, first_name: "Alain") }
  let!(:pro2) { create(:pro, first_name: "Robert") }
  let!(:motif) { create(:motif) }
  let!(:motif_with_limit) { create(:motif, max_users_limit: 2) }
  let!(:user) { create(:user) }

  before do
    login_as(pro, scope: :pro)
    visit authenticated_root_path

    expect(user.rdvs.count).to eq(0)
    click_link('Créer un rendez-vous')
  end

  scenario "default" do
    # Step 1
    expect_page_title("Choisir le motif")
    select(motif.id.to_s, from: "rdv_motif_id")
    click_button('Continuer')

    # Step 2
    expect_page_title("Choisir la durée et la date")
    expect_checked(motif.name)
    expect(page).to have_selector("input#rdv_duration_in_min[value='#{motif.default_duration_in_min}']")
    fill_in 'Lieu', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes"
    fill_in 'Durée en minutes', with: '35'
    fill_in 'Commence à', with: '12/10/2019 à 14h15'

    select_pro(pro)
    select_pro(pro2)
    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("Motif : #{motif.name}")
    expect_checked("Lieu : 79 Rue de Plaisance, 92250 La Garenne-Colombes")
    expect_checked("Durée : 35 minutes")
    expect_checked("Professionnels : #{pro.full_name_and_specialite} et #{pro2.full_name_and_specialite}")
    expect_checked("Commence le : samedi 12 octobre 2019 à 14h15")

    select_user(user)

    click_button('Continuer')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users).to contain_exactly(user)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(35)
    expect(rdv.start_at).to eq(Time.zone.local(2019, 10, 12, 14, 15))
  end

  scenario "with a users limit" do
    expect_page_title("Choisir le motif")
    select(motif_with_limit.id.to_s, from: "rdv_motif_id")
    click_button('Continuer')

    # Step 2
    expect_page_title("Choisir la durée et la date")
    expect_checked("Motif : #{motif_with_limit.name}")
    select_pro(pro)
    fill_in "Limite du nombre d'usagers", with: '4'

    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("4 usagers maximum")

    select_user(user)

    click_button('Continuer')

    expect(user.rdvs.last.max_users_limit).to eq(4)
  end

  def select_pro(pro)
    select(pro.full_name_and_specialite, from: 'rdv_pro_ids')
  end

  def select_user(user)
    select(user.full_name, from: 'rdv_user_ids')
  end

  def expect_page_title(title)
    expect(page).to have_selector('h4.page-title', text: title)
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
