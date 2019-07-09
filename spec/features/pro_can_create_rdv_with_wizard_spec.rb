describe "Pro can create a Rdv with wizard" do
  let(:pro) { create(:pro) }
  let!(:motif) { create(:motif, organisation: pro.organisation) }
  let!(:motif_with_limit) { create(:motif, organisation: pro.organisation, max_users_limit: 2) }
  let!(:user) { create(:user, organisation: pro.organisation) }

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
    fill_in 'Durée en minutes', with: '35'

    select('12', from: 'rdv_start_at_3i')
    select('octobre', from: 'rdv_start_at_2i')
    select('2019', from: 'rdv_start_at_1i')
    select('14', from: 'rdv_start_at_4i')
    select('15', from: 'rdv_start_at_5i')

    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked(motif.name)
    expect_checked("Durée : 35 minutes")
    expect_checked("Commence à : 12 octobre 2019 14h 15min 00s")

    select(user.full_name, from: 'rdv_user_id')

    click_button('Continuer')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.user).to eq(user)
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
    expect_checked(motif_with_limit.name)
    fill_in "Limite du nombre d'usagers", with: '4'

    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("4 usagers maximum")

    select(user.full_name, from: 'rdv_user_id')

    click_button('Continuer')

    expect(user.rdvs.last.max_users_limit).to eq(4)
  end

  def expect_page_title(title)
    expect(page).to have_selector('h4.page-title', text: title)
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
