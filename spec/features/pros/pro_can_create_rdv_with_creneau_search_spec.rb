describe "Pro can create a Rdv with creneau search" do
  let!(:pro) { create(:pro, first_name: "Alain") }
  let!(:pro2) { create(:pro, first_name: "Robert") }
  let!(:motif) { create(:motif, online: true) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, pro: pro) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, pro: pro2) }

  before do
    login_as(pro, scope: :pro)
    visit authenticated_pro_root_path

    expect(user.rdvs.count).to eq(0)
    click_link('Trouver un créneau')
  end

  scenario "default", js: true do
    expect_page_title("Choisir un créneau")
    select(motif.name, from: "creneau_pro_search_motif_id")
    click_button('Afficher les créneaux')

    # Display results for both lieux
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).to have_content(plage_ouverture2.lieu.address)
    expect(page).to have_content(plage_ouverture.pro.short_name)
    expect(page).to have_content(plage_ouverture2.pro.short_name)

    # Add a filter on lieu
    select(lieu.name, from: "creneau_pro_search_lieu_id")
    click_button('Afficher les créneaux')
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).not_to have_content(plage_ouverture2.lieu.address)

    # Change to a pro filter
    select("Sélectionnez un lieu", from: "creneau_pro_search_lieu_id")
    select(pro.full_name, from: "creneau_pro_search_pro_ids")
    click_button('Afficher les créneaux')
    expect(page).to have_content(plage_ouverture.pro.short_name)
    expect(page).not_to have_content(plage_ouverture2.pro.short_name)

    # Select creneau
    first(:link, "09:30").click

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("Motif : #{motif.name}")
    expect_checked("Lieu : #{lieu.address}")
    expect_checked("Durée : #{motif.default_duration_in_min} minutes")
    expect_checked("Professionnels : #{pro.full_name_and_service}")

    select_user(user)

    click_button('Continuer')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users).to contain_exactly(user)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(motif.default_duration_in_min)

    expect(page).to have_content("Le rendez-vous a été créé.")
  end

  def select_user(user)
    select(user.full_name, from: 'rdv_user_ids')
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
