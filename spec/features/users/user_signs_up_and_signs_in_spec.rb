feature 'User signs up and signs in' do
  let(:user) { build(:user) }

  context 'through home page' do
    before { visit root_path }

    scenario '.sign_up, .confirm, .sign_in and then signs out' do
      click_link 'Se connecter'
      click_link 'Je m\'inscris'
      sign_up(user)
      expect(current_path).to eq(new_user_session_path)
      expect_flash_info(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
      open_email(user.email)
      current_email.click_link 'Confirmer mon compte'
      expect_flash_info(I18n.t("devise.confirmations.confirmed"))
      sign_in(user)
      expect(current_path).to eq(authenticated_user_root_path)
      expect_flash_info(I18n.t("devise.sessions.signed_in"))
      click_link user.first_name
      click_link 'Se déconnecter'
      expect(current_path).to eq(root_path)
    end
  end

  def sign_up(user)
    fill_in :user_first_name, with: user.first_name
    fill_in :user_last_name, with: user.last_name
    fill_in :user_email, with: user.email
    fill_in :password, with: user.password
    click_on "Je m'inscris"
  end

  def expect_flash_info(message)
    expect(page).to have_selector('.alert.alert-info', text: message)
  end
end
