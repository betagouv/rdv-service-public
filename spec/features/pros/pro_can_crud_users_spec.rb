describe "Pro can CRUD users" do
  let!(:pro) { create(:pro) }
  let!(:user) { create(:user) }
  let(:new_user) { build(:user) }

  before do
    login_as(pro, scope: :pro)
    visit authenticated_pro_root_path
    click_link "Vos usagers"
  end

  scenario "default" do
    expect_page_title("Vos usagers")

    expect(user.encrypted_password).not_to be_nil
    click_link user.full_name
    expect_page_title("Modifier l'usager")
    fill_in 'Prénom', with: 'Alberto'
    fill_in 'Email', with: 'lenouvel@email.com'
    click_button('Modifier')

    # When the user has already a pwd, changing email send a confirmation email
    open_email('lenouvel@email.com')
    expect(current_email.subject).to eq I18n.t("devise.mailer.confirmation_instructions.subject")

    expect_page_title("Vos usagers")
    click_link "Alberto #{user.last_name}"

    expect(page).to have_content('En attente de confirmation pour lenouvel@email.com')
    click_link('Supprimer')

    expect_page_title("Vos usagers")
    expect_page_with_no_record_text("Vous n'avez pas encore ajouté d'usager.")

    click_link 'Créer un usager', match: :first

    expect_page_title("Nouvel usager")
    fill_in 'Prénom', with: new_user.first_name
    fill_in 'Nom', with: new_user.last_name
    click_button 'Créer'

    expect_page_title("Vos usagers")
    click_link new_user.full_name
    expect(page).to have_no_content('Inviter')

    fill_in 'Email', with: new_user.email
    click_button 'Modifier'
    click_link new_user.full_name
    click_link 'Inviter'

    open_email(new_user.email)
    expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
  end
end
