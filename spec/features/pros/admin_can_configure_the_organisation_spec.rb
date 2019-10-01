describe "Admin can configure the organisation" do
  let!(:pro_admin) { create(:pro, :admin) }
  let!(:pro_user) { create(:pro) }
  let!(:motif) { create(:motif) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu) }

  before do
    login_as(pro_admin, scope: :pro)
    visit authenticated_pro_root_path
    click_link "Paramètres"
  end

  scenario "CRUD on lieux" do
    click_link "Vos lieux"
    expect_page_title("Vos lieux de consultation")

    click_link lieu.name
    expect_page_title("Modifier le lieu")
    fill_in 'Nom', with: 'Le nouveau lieu'
    click_button('Modifier')

    expect_page_title("Vos lieux de consultation")
    click_link 'Le nouveau lieu'

    click_link('Supprimer')

    expect_page_title("Vos lieux de consultation")
    expect_page_with_no_record_text("Vous n'avez pas encore ajouté de lieu de consultation.")
  end

  scenario "CRUD on pros" do
    click_link "Vos professionnels"
    expect_page_title("Vos professionnels")

    click_link pro_user.full_name
    expect_page_title("Modifier le professionnel")
    choose :pro_permission_role_admin
    click_button('Modifier')

    expect_page_title("Vos professionnels")
    expect(page).to have_selector('span.badge.badge-danger', count: 2)

    click_link pro_user.full_name
    click_link('Supprimer')

    expect_page_title("Vos professionnels")
    expect(page).to have_no_content(pro_user.full_name)

    click_link 'Inviter un professionnel', match: :first
    fill_in 'Email', with: 'jean@paul.com'
    click_button 'Envoyer une invitation'

    expect_page_title("Vos professionnels")
    expect(page).to have_content('jean@paul.com')

    open_email('jean@paul.com')
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end

  scenario "CRUD on motifs" do 
    click_link "Vos motifs"
    expect_page_title("Vos motifs")

    click_link motif.name
    expect_page_title("Modifier le motif")
    fill_in :motif_name, with: 'Le nouveau motif'
    click_button('Modifier')

    expect_page_title("Vos motifs")
    click_link 'Le nouveau motif'

    click_link('Supprimer')
    expect_page_title("Vos motifs")
    expect_page_with_no_record_text("Vous n'avez pas encore créé de motif.")
  end
end
